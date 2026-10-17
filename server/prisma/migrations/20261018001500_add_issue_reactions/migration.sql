-- DEV-11 좋아요와 스크랩. 사용자별·호별로 한 번만 저장한다.

CREATE TABLE "likes" (
    "user_id" UUID NOT NULL,
    "issue_id" UUID NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "likes_pkey" PRIMARY KEY ("user_id", "issue_id")
);

CREATE TABLE "scraps" (
    "user_id" UUID NOT NULL,
    "issue_id" UUID NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "scraps_pkey" PRIMARY KEY ("user_id", "issue_id")
);

CREATE INDEX "likes_issue_id_created_at_idx" ON "likes"("issue_id", "created_at");
CREATE INDEX "scraps_issue_id_created_at_idx" ON "scraps"("issue_id", "created_at");

ALTER TABLE "likes"
ADD CONSTRAINT "likes_user_id_fkey"
FOREIGN KEY ("user_id") REFERENCES "users"("id")
ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "likes"
ADD CONSTRAINT "likes_issue_id_fkey"
FOREIGN KEY ("issue_id") REFERENCES "issues"("id")
ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "scraps"
ADD CONSTRAINT "scraps_user_id_fkey"
FOREIGN KEY ("user_id") REFERENCES "users"("id")
ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "scraps"
ADD CONSTRAINT "scraps_issue_id_fkey"
FOREIGN KEY ("issue_id") REFERENCES "issues"("id")
ON DELETE CASCADE ON UPDATE CASCADE;
