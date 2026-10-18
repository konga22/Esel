-- CreateTable
CREATE TABLE "friendships" (
    "id" UUID NOT NULL,
    "user_a_id" UUID NOT NULL,
    "user_b_id" UUID NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "friendships_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "friendships_ordered_users" CHECK ("user_a_id" < "user_b_id")
);

-- CreateTable
CREATE TABLE "friend_requests" (
    "id" UUID NOT NULL,
    "pair_key" VARCHAR(73) NOT NULL,
    "sender_id" UUID NOT NULL,
    "receiver_id" UUID NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "friend_requests_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "friend_requests_different_users" CHECK ("sender_id" <> "receiver_id")
);

-- CreateIndex
CREATE UNIQUE INDEX "friendships_user_a_id_user_b_id_key" ON "friendships"("user_a_id", "user_b_id");

-- CreateIndex
CREATE INDEX "friendships_user_a_id_created_at_id_idx" ON "friendships"("user_a_id", "created_at", "id");

-- CreateIndex
CREATE INDEX "friendships_user_b_id_created_at_id_idx" ON "friendships"("user_b_id", "created_at", "id");

-- CreateIndex
CREATE UNIQUE INDEX "friend_requests_pair_key_key" ON "friend_requests"("pair_key");

-- CreateIndex
CREATE INDEX "friend_requests_receiver_id_created_at_id_idx" ON "friend_requests"("receiver_id", "created_at", "id");

-- AddForeignKey
ALTER TABLE "friendships" ADD CONSTRAINT "friendships_user_a_id_fkey" FOREIGN KEY ("user_a_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "friendships" ADD CONSTRAINT "friendships_user_b_id_fkey" FOREIGN KEY ("user_b_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "friend_requests" ADD CONSTRAINT "friend_requests_sender_id_fkey" FOREIGN KEY ("sender_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "friend_requests" ADD CONSTRAINT "friend_requests_receiver_id_fkey" FOREIGN KEY ("receiver_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
