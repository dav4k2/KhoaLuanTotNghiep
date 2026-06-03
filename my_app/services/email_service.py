# my_app/services/email_service.py

import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

from config import settings


class EmailService:
    """Gửi email qua Gmail SMTP"""

    @staticmethod
    def send_otp_email(to_email: str, otp_code: str) -> bool:
        """
        Gửi email chứa mã OTP đến người dùng.
        Trả về True nếu thành công, False nếu thất bại.
        """
        try:
            # Tạo email
            msg = MIMEMultipart("alternative")
            msg["Subject"] = "Mã xác nhận đặt lại mật khẩu"
            msg["From"]    = settings.MAIL_FROM
            msg["To"]      = to_email

            # Nội dung HTML
            html_body = f"""
            <html>
            <body style="font-family: Arial, sans-serif; background-color: #f4f4f4; padding: 20px;">
                <div style="max-width: 480px; margin: auto; background: white;
                            border-radius: 12px; padding: 32px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">

                    <h2 style="color: #1E6E38; text-align: center;">
                        🌿 Trợ lý Nông nghiệp Thông minh
                    </h2>

                    <p style="color: #333; font-size: 15px;">Xin chào,</p>
                    <p style="color: #333; font-size: 15px;">
                        Bạn vừa yêu cầu đặt lại mật khẩu. Đây là mã xác nhận của bạn:
                    </p>

                    <!-- Mã OTP nổi bật -->
                    <div style="text-align: center; margin: 28px 0;">
                        <span style="font-size: 42px; font-weight: bold;
                                     letter-spacing: 10px; color: #1E6E38;
                                     background: #E6F4EA; padding: 12px 24px;
                                     border-radius: 8px;">
                            {otp_code}
                        </span>
                    </div>

                    <p style="color: #666; font-size: 13px; text-align: center;">
                        ⏱ Mã có hiệu lực trong <strong>5 phút</strong>
                    </p>

                    <hr style="border: none; border-top: 1px solid #eee; margin: 24px 0;">

                    <p style="color: #999; font-size: 12px; text-align: center;">
                        Nếu bạn không yêu cầu đặt lại mật khẩu, hãy bỏ qua email này.
                    </p>
                </div>
            </body>
            </html>
            """

            msg.attach(MIMEText(html_body, "html"))

            # Gửi qua Gmail SMTP
            with smtplib.SMTP_SSL("smtp.gmail.com", 465) as server:
                server.login(settings.MAIL_USERNAME, settings.MAIL_PASSWORD)
                server.sendmail(settings.MAIL_FROM, to_email, msg.as_string())

            return True

        except Exception as e:
            print(f"[EmailService] Lỗi gửi email: {e}")
            return False