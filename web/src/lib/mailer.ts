import * as tls from "tls";
import * as dns from "dns";

/** Connection-level failures worth retrying; SMTP protocol rejections (5xx) are not. */
function isRetryable(err: unknown): boolean {
  const codes = new Set(["ETIMEDOUT", "ECONNREFUSED", "ENETUNREACH", "ECONNRESET", "EHOSTUNREACH"]);
  const errors: unknown[] =
    err instanceof AggregateError ? err.errors : [err];
  return errors.some((e) => codes.has((e as NodeJS.ErrnoException)?.code ?? ""));
}

const delay = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

/**
 * Send an HTML email via Gmail SMTP on port 465 (SMTPS — direct TLS).
 * Requires SMTP_USER, SMTP_PASS, and optionally SMTP_FROM env vars.
 * When env vars are missing, logs and returns silently.
 *
 * Port 465 (direct TLS) is used instead of 587 (STARTTLS) because many
 * ISPs and development networks block outbound port 587.
 */
export async function sendMail(opts: {
  to: string;
  subject: string;
  html: string;
}): Promise<void> {
  const user = process.env.SMTP_USER;
  const pass = process.env.SMTP_PASS;
  const from = process.env.SMTP_FROM ?? user;

  if (!user || !pass) {
    console.warn("[mailer] SMTP not configured — skipping email to:", opts.to);
    return;
  }

  const attempts = 3;
  for (let attempt = 1; attempt <= attempts; attempt++) {
    try {
      await sendOnce({ user, pass, from: from!, ...opts });
      return;
    } catch (err) {
      const isLast = attempt === attempts;
      if (!isRetryable(err) || isLast) throw err;
      console.warn(`[mailer] send attempt ${attempt} failed, retrying:`, (err as Error).message);
      await delay(attempt * 750);
    }
  }
}

async function sendOnce(opts: {
  to: string;
  subject: string;
  html: string;
  user: string;
  pass: string;
  from: string;
}): Promise<void> {
  const { user, pass, from } = opts;

  const encodedSubject = /[^\x00-\x7F]/.test(opts.subject)
    ? `=?UTF-8?B?${Buffer.from(opts.subject, "utf8").toString("base64")}?=`
    : opts.subject;

  const bodyB64 = Buffer.from(opts.html, "utf8")
    .toString("base64")
    .match(/.{1,76}/g)!
    .join("\r\n");

  const message =
    `From: ${from}\r\n` +
    `To: ${opts.to}\r\n` +
    `Subject: ${encodedSubject}\r\n` +
    `MIME-Version: 1.0\r\n` +
    `Content-Type: text/html; charset=UTF-8\r\n` +
    `Content-Transfer-Encoding: base64\r\n` +
    `\r\n` +
    bodyB64 +
    `\r\n.\r\n`;

  return new Promise<void>((resolve, reject) => {
    let settled = false;
    const settle = (err?: Error) => {
      if (settled) return;
      settled = true;
      err ? reject(err) : resolve();
    };

    type State = "greeting" | "ehlo" | "auth" | "mail_from" | "rcpt_to" | "data_cmd" | "data_body" | "quit";
    let state: State = "greeting";
    let buf = "";

    const write = (cmd: string) => socket.write(cmd + "\r\n");

    const onFinalLine = (code: number, text: string) => {
      if (code >= 500) return settle(new Error(`SMTP ${code}: ${text}`));

      switch (state) {
        case "greeting":
          write("EHLO nexus.app");
          state = "ehlo";
          break;

        case "ehlo":
          if (code === 250) {
            const plain = Buffer.from(`\0${user}\0${pass}`).toString("base64");
            write(`AUTH PLAIN ${plain}`);
            state = "auth";
          }
          break;

        case "auth":
          if (code === 235) {
            write(`MAIL FROM:<${user}>`);
            state = "mail_from";
          } else {
            settle(new Error(`SMTP auth failed ${code}: ${text}`));
          }
          break;

        case "mail_from":
          if (code === 250) {
            write(`RCPT TO:<${opts.to}>`);
            state = "rcpt_to";
          } else {
            settle(new Error(`SMTP MAIL FROM failed ${code}: ${text}`));
          }
          break;

        case "rcpt_to":
          if (code === 250) {
            write("DATA");
            state = "data_cmd";
          } else {
            settle(new Error(`SMTP RCPT TO failed ${code}: ${text}`));
          }
          break;

        case "data_cmd":
          if (code === 354) {
            socket.write(message);
            state = "data_body";
          } else {
            settle(new Error(`SMTP DATA failed ${code}: ${text}`));
          }
          break;

        case "data_body":
          if (code === 250) {
            write("QUIT");
            state = "quit";
          } else {
            settle(new Error(`SMTP message rejected ${code}: ${text}`));
          }
          break;

        case "quit":
          socket.end();
          settle();
          break;
      }
    };

    const handleData = (chunk: Buffer) => {
      buf += chunk.toString("utf8");
      let idx: number;
      while ((idx = buf.indexOf("\r\n")) !== -1) {
        const line = buf.slice(0, idx);
        buf = buf.slice(idx + 2);
        if (!line) continue;
        // Only process final lines in a multi-line response (4th char is space, not dash)
        if (line[3] !== "-") {
          onFinalLine(parseInt(line.slice(0, 3), 10), line.slice(4));
        }
      }
    };

    // Port 465 = SMTPS: TLS from the first byte, no STARTTLS handshake needed.
    // Force IPv4 resolution — this environment has no real IPv6 route, so letting
    // Node resolve/attempt AAAA records only adds a guaranteed-failing attempt.
    const socket = tls.connect(
      {
        host: "smtp.gmail.com",
        port: 465,
        servername: "smtp.gmail.com",
        lookup: (hostname, options, callback) =>
          dns.lookup(hostname, { ...options, family: 4 }, callback),
      },
      () => { /* TLS established — wait for server greeting */ }
    );

    socket.setTimeout(10_000, () => {
      socket.destroy();
      const err = Object.assign(new Error("SMTP connection timed out"), { code: "ETIMEDOUT" });
      settle(err);
    });

    socket.on("data", handleData);
    socket.on("error", settle);
    socket.on("close", () => {
      if (!settled) settle(new Error(`SMTP socket closed unexpectedly in state: ${state}`));
    });
  });
}
