-- DEV-19 사용자별 알림 설정. 푸시 발송 서비스와는 분리해 수신 선호만 저장한다.

CREATE TABLE "notification_settings" (
    "user_id" UUID NOT NULL,
    "enabled" BOOLEAN NOT NULL DEFAULT true,
    "new_issue" BOOLEAN NOT NULL DEFAULT true,
    "reactions" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "notification_settings_pkey" PRIMARY KEY ("user_id")
);

ALTER TABLE "notification_settings"
ADD CONSTRAINT "notification_settings_user_id_fkey"
FOREIGN KEY ("user_id") REFERENCES "users"("id")
ON DELETE CASCADE ON UPDATE CASCADE;
