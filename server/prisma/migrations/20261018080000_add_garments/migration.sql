CREATE TABLE "garments" (
    "id" UUID NOT NULL,
    "owner_id" UUID NOT NULL,
    "kind" VARCHAR(20) NOT NULL,
    "name" VARCHAR(40) NOT NULL DEFAULT '',
    "note" VARCHAR(20) NOT NULL DEFAULT '',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    CONSTRAINT "garments_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "issue_garments" (
    "issue_id" UUID NOT NULL,
    "garment_id" UUID NOT NULL,
    "position" SMALLINT NOT NULL,
    "today_color" BOOLEAN NOT NULL DEFAULT false,
    "x" DOUBLE PRECISION,
    "y" DOUBLE PRECISION,
    CONSTRAINT "issue_garments_pkey" PRIMARY KEY ("issue_id", "garment_id"),
    CONSTRAINT "issue_garments_coordinates_check" CHECK (("x" IS NULL AND "y" IS NULL) OR ("x" BETWEEN 0 AND 1 AND "y" BETWEEN 0 AND 1))
);

CREATE INDEX "garments_owner_id_created_at_id_idx" ON "garments"("owner_id", "created_at", "id");
CREATE UNIQUE INDEX "issue_garments_issue_id_position_key" ON "issue_garments"("issue_id", "position");

ALTER TABLE "garments" ADD CONSTRAINT "garments_owner_id_fkey" FOREIGN KEY ("owner_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "issue_garments" ADD CONSTRAINT "issue_garments_issue_id_fkey" FOREIGN KEY ("issue_id") REFERENCES "issues"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "issue_garments" ADD CONSTRAINT "issue_garments_garment_id_fkey" FOREIGN KEY ("garment_id") REFERENCES "garments"("id") ON DELETE CASCADE ON UPDATE CASCADE;
