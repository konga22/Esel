CREATE TYPE "TwinVisibility" AS ENUM ('PRIVATE', 'SOLO', 'JOINT');

ALTER TABLE "profiles"
ADD COLUMN "bio" VARCHAR(80) NOT NULL DEFAULT '';

ALTER TABLE "twins"
ADD COLUMN "published_at" TIMESTAMP(3);

ALTER TABLE "twin_participations"
ADD COLUMN "visibility" "TwinVisibility",
ADD COLUMN "consented_at" TIMESTAMP(3);
