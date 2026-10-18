CREATE TYPE "TwinStatus" AS ENUM ('INVITED', 'ACCEPTED');
CREATE TYPE "TwinRole" AS ENUM ('INVITER', 'INVITEE');

CREATE TABLE "twins" (
    "id" UUID NOT NULL,
    "service_date" DATE NOT NULL,
    "status" "TwinStatus" NOT NULL DEFAULT 'INVITED',
    "accepted_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    CONSTRAINT "twins_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "twin_participations" (
    "twin_id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "service_date" DATE NOT NULL,
    "role" "TwinRole" NOT NULL,
    "choice_color_id" VARCHAR(32),
    CONSTRAINT "twin_participations_pkey" PRIMARY KEY ("twin_id", "user_id")
);

CREATE TABLE "twin_candidates" (
    "twin_id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "color_id" VARCHAR(32) NOT NULL,
    "position" SMALLINT NOT NULL,
    CONSTRAINT "twin_candidates_pkey" PRIMARY KEY ("twin_id", "user_id", "color_id")
);

CREATE TABLE "twin_posts" (
    "twin_id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "media_id" UUID NOT NULL,
    "color_id" VARCHAR(32) NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "twin_posts_pkey" PRIMARY KEY ("twin_id", "user_id")
);

CREATE INDEX "twins_service_date_status_idx" ON "twins"("service_date", "status");
CREATE UNIQUE INDEX "twin_participations_user_id_service_date_key" ON "twin_participations"("user_id", "service_date");
CREATE UNIQUE INDEX "twin_participations_twin_id_role_key" ON "twin_participations"("twin_id", "role");
CREATE UNIQUE INDEX "twin_candidates_twin_id_user_id_position_key" ON "twin_candidates"("twin_id", "user_id", "position");
CREATE UNIQUE INDEX "twin_posts_media_id_key" ON "twin_posts"("media_id");

ALTER TABLE "twin_participations" ADD CONSTRAINT "twin_participations_twin_id_fkey" FOREIGN KEY ("twin_id") REFERENCES "twins"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "twin_participations" ADD CONSTRAINT "twin_participations_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "twin_participations" ADD CONSTRAINT "twin_participations_choice_color_id_fkey" FOREIGN KEY ("choice_color_id") REFERENCES "colors"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "twin_candidates" ADD CONSTRAINT "twin_candidates_twin_id_user_id_fkey" FOREIGN KEY ("twin_id", "user_id") REFERENCES "twin_participations"("twin_id", "user_id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "twin_candidates" ADD CONSTRAINT "twin_candidates_color_id_fkey" FOREIGN KEY ("color_id") REFERENCES "colors"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "twin_posts" ADD CONSTRAINT "twin_posts_twin_id_user_id_fkey" FOREIGN KEY ("twin_id", "user_id") REFERENCES "twin_participations"("twin_id", "user_id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "twin_posts" ADD CONSTRAINT "twin_posts_media_id_fkey" FOREIGN KEY ("media_id") REFERENCES "media_assets"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "twin_posts" ADD CONSTRAINT "twin_posts_color_id_fkey" FOREIGN KEY ("color_id") REFERENCES "colors"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
