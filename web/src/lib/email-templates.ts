export function otpEmailHtml(code: string): string {
  return `<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
</head>
<body style="margin:0;padding:0;background:#f4f4f5;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="padding:40px 16px;">
    <tr>
      <td align="center">
        <table width="480" cellpadding="0" cellspacing="0" style="background:#ffffff;border-radius:16px;overflow:hidden;border:1px solid #e4e4e7;">

          <tr>
            <td style="background:#0ec4a0;padding:28px 32px;text-align:center;">
              <span style="font-size:32px;font-weight:700;color:#ffffff;letter-spacing:-1px;">N</span>
              <p style="margin:8px 0 0;color:#ffffff;font-size:15px;opacity:0.9;">Nexus</p>
            </td>
          </tr>

          <tr>
            <td style="padding:36px 32px;text-align:center;">
              <p style="margin:0 0 8px;font-size:22px;font-weight:600;color:#18181b;">Verify your email</p>
              <p style="margin:0 0 32px;font-size:15px;color:#71717a;line-height:1.6;">
                Enter the code below to confirm your Nexus account.
              </p>

              <div style="display:inline-block;background:#f4f4f5;border-radius:12px;padding:20px 36px;margin-bottom:32px;">
                <span style="font-size:36px;font-weight:700;letter-spacing:10px;color:#18181b;">${code}</span>
              </div>

              <p style="margin:0;font-size:13px;color:#a1a1aa;">
                This code expires in 15 minutes. If you didn't create a Nexus account, you can safely ignore this email.
              </p>
            </td>
          </tr>

          <tr>
            <td style="padding:20px 32px;border-top:1px solid #f4f4f5;text-align:center;">
              <p style="margin:0;font-size:12px;color:#a1a1aa;">&copy; 2026 Nexus &middot; All rights reserved</p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>
</body>
</html>`;
}

export function welcomeEmailHtml(name: string | null): string {
  const greeting = name ? `Hi ${name},` : "Welcome aboard,";
  return `<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
</head>
<body style="margin:0;padding:0;background:#f4f4f5;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="padding:40px 16px;">
    <tr>
      <td align="center">
        <table width="480" cellpadding="0" cellspacing="0" style="background:#ffffff;border-radius:16px;overflow:hidden;border:1px solid #e4e4e7;">

          <tr>
            <td style="background:#0ec4a0;padding:28px 32px;text-align:center;">
              <span style="font-size:32px;font-weight:700;color:#ffffff;letter-spacing:-1px;">N</span>
              <p style="margin:8px 0 0;color:#ffffff;font-size:15px;opacity:0.9;">Nexus</p>
            </td>
          </tr>

          <tr>
            <td style="padding:36px 32px;text-align:center;">
              <p style="margin:0 0 8px;font-size:22px;font-weight:600;color:#18181b;">${greeting}</p>
              <p style="margin:0 0 24px;font-size:15px;color:#71717a;line-height:1.6;">
                Your Nexus account is ready. Explore geo-contextual news, take daily quizzes,
                and stay ahead of what's happening around the world.
              </p>
              <a href="https://nexus.app/feed"
                 style="display:inline-block;padding:14px 32px;background:#0ec4a0;color:#ffffff;font-weight:600;font-size:15px;border-radius:12px;text-decoration:none;">
                Go to your feed
              </a>
            </td>
          </tr>

          <tr>
            <td style="padding:20px 32px;border-top:1px solid #f4f4f5;text-align:center;">
              <p style="margin:0;font-size:12px;color:#a1a1aa;">&copy; 2026 Nexus &middot; All rights reserved</p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>
</body>
</html>`;
}
