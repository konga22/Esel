-- DEV-11 독자 한 줄과 DEV-13 잡지 구독.

CREATE TABLE "reader_lines" (
    "id" UUID NOT NULL,
    "author_id" UUID NOT NULL,
    "issue_id" UUID NOT NULL,
    "text" VARCHAR(60) NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "reader_lines_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "subscriptions" (
    "subscriber_id" UUID NOT NULL,
    "magazine_id" UUID NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "subscriptions_pkey" PRIMARY KEY ("subscriber_id", "magazine_id")
);

CREATE INDEX "reader_lines_issue_id_created_at_id_idx" ON "reader_lines"("issue_id", "created_at", "id");
CREATE INDEX "subscriptions_magazine_id_created_at_idx" ON "subscriptions"("magazine_id", "created_at");

ALTER TABLE "reader_lines"
ADD CONSTRAINT "reader_lines_author_id_fkey"
FOREIGN KEY ("author_id") REFERENCES "users"("id")
ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "reader_lines"
ADD CONSTRAINT "reader_lines_issue_id_fkey"
FOREIGN KEY ("issue_id") REFERENCES "issues"("id")
ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "subscriptions"
ADD CONSTRAINT "subscriptions_subscriber_id_fkey"
FOREIGN KEY ("subscriber_id") REFERENCES "users"("id")
ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "subscriptions"
ADD CONSTRAINT "subscriptions_magazine_id_fkey"
FOREIGN KEY ("magazine_id") REFERENCES "users"("id")
ON DELETE CASCADE ON UPDATE CASCADE;
