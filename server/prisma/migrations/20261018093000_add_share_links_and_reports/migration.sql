CREATE TABLE "share_links" (
    "id" UUID NOT NULL,
    "creator_id" UUID NOT NULL,
    "token_hash" CHAR(64) NOT NULL,
    "issue_id" UUID,
    "twin_id" UUID,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "share_links_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "share_links_one_target_check" CHECK (("issue_id" IS NOT NULL) <> ("twin_id" IS NOT NULL))
);

CREATE TABLE "reports" (
    "id" UUID NOT NULL,
    "reporter_id" UUID NOT NULL,
    "issue_id" UUID NOT NULL,
    "line_id" UUID,
    "reason" VARCHAR(32) NOT NULL,
    "details" VARCHAR(500) NOT NULL DEFAULT '',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "reports_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "share_links_token_hash_key" ON "share_links"("token_hash");
CREATE INDEX "share_links_issue_id_idx" ON "share_links"("issue_id");
CREATE INDEX "share_links_twin_id_idx" ON "share_links"("twin_id");
CREATE INDEX "reports_reporter_id_created_at_idx" ON "reports"("reporter_id", "created_at");
CREATE INDEX "reports_issue_id_idx" ON "reports"("issue_id");
CREATE INDEX "reports_line_id_idx" ON "reports"("line_id");

ALTER TABLE "share_links" ADD CONSTRAINT "share_links_creator_id_fkey" FOREIGN KEY ("creator_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "share_links" ADD CONSTRAINT "share_links_issue_id_fkey" FOREIGN KEY ("issue_id") REFERENCES "issues"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "share_links" ADD CONSTRAINT "share_links_twin_id_fkey" FOREIGN KEY ("twin_id") REFERENCES "twins"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "reports" ADD CONSTRAINT "reports_reporter_id_fkey" FOREIGN KEY ("reporter_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "reports" ADD CONSTRAINT "reports_issue_id_fkey" FOREIGN KEY ("issue_id") REFERENCES "issues"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "reports" ADD CONSTRAINT "reports_line_id_fkey" FOREIGN KEY ("line_id") REFERENCES "reader_lines"("id") ON DELETE CASCADE ON UPDATE CASCADE;
