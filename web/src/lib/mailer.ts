import * as net from "net";
import * as tls from "tls";

type SmtpState =
  | "greeting"
  | "ehlo"
  | "starttls"
  | "ehlo2"
  | "auth"
  | "mail_from"
  | "rcpt_to"
  | "data_cmd"
  | "data_body"
  | "quit";

/**
 * Send an HTML email via Gmail SMTP on port 587 (STARTTLS).
 * Requires SMTP_USER, SMTP_PASS, and optionally SMTP_FROM env vars.
 * When env vars are missing, logs and returns silently.
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

    let buf = "";
    let state: SmtpState = "greeting";
    let activeSocket: net.Socket | tls.TLSSocket;

    const write = (cmd: string) => activeSocket.write(cmd + "\r\n");

    const onFinalLine = (code: number, text: string) => {
      if (code >= 500) return settle(new Error(`SMTP ${code}: ${text}`));

      switch (state) {
        case "greeting":
          write("EHLO nexus.app");
          state = "ehlo";
          break;

        case "ehlo":
          if (code === 250) {
            write("STARTTLS");
            state = "starttls";
          }
          break;

        case "starttls":
          if (code === 220) {
            buf = "";
            const tlsSock = tls.connect(
              { socket: plainSocket, servername: "smtp.gmail.com" },
              () => {
                activeSocket = tlsSock;
                write("EHLO nexus.app");
                state = "ehlo2";
              }
            );
            tlsSock.on("data", handleData);
            tlsSock.on("error", settle);
            tlsSock.on("close", () => {
              if (!settled) settle(new Error(`SMTP TLS closed in state: ${state}`));
            });
          } else {
            settle(new Error(`SMTP STARTTLS failed ${code}: ${text}`));
          }
          break;

        case "ehlo2":
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
            activeSocket.write(message);
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
          activeSocket.end();
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
        if (line[3] !== "-") {
          onFinalLine(parseInt(line.slice(0, 3), 10), line.slice(4));
        }
      }
    };

    // Port 587 = STARTTLS (plain TCP → upgrade to TLS after EHLO)
    // More commonly open than 465 (SMTPS)
    const plainSocket = net.createConnection({ host: "smtp.gmail.com", port: 587 });
    activeSocket = plainSocket;

    plainSocket.on("data", handleData);
    plainSocket.on("error", settle);
    plainSocket.on("close", () => {
      // Only fail on unexpected close (not after TLS takes over the socket)
      if (!settled && state !== "quit" && state !== "starttls") {
        settle(new Error(`SMTP plain socket closed in state: ${state}`));
      }
    });
  });
}
