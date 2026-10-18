ALTER TABLE "issues" ADD COLUMN "deleted_at" TIMESTAMP(3);

CREATE TABLE "blocks" (
    "id" UUID NOT NULL,
    "blocker_id" UUID NOT NULL,
    "blocked_id" UUID NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "blocks_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "blocks_not_self_check" CHECK ("blocker_id" <> "blocked_id")
);

CREATE UNIQUE INDEX "blocks_blocker_id_blocked_id_key" ON "blocks"("blocker_id", "blocked_id");
CREATE INDEX "blocks_blocker_id_created_at_id_idx" ON "blocks"("blocker_id", "created_at", "id");
CREATE INDEX "blocks_blocked_id_idx" ON "blocks"("blocked_id");
CREATE INDEX "issues_deleted_at_idx" ON "issues"("deleted_at");

ALTER TABLE "blocks" ADD CONSTRAINT "blocks_blocker_id_fkey" FOREIGN KEY ("blocker_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "blocks" ADD CONSTRAINT "blocks_blocked_id_fkey" FOREIGN KEY ("blocked_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
