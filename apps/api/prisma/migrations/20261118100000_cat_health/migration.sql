-- CreateTable
CREATE TABLE "cat_health" (
    "id" UUID NOT NULL,
    "cat_id" UUID NOT NULL,
    "type" TEXT NOT NULL,
    "detail" JSONB NOT NULL,
    "attachments" TEXT[] NOT NULL DEFAULT '{}',
    "record_date" DATE NOT NULL,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "cat_health_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "cat_health_cat_id_type_record_date_idx" ON "cat_health"("cat_id", "type", "record_date");

-- AddForeignKey
ALTER TABLE "cat_health" ADD CONSTRAINT "cat_health_cat_id_fkey" FOREIGN KEY ("cat_id") REFERENCES "cats"("id") ON DELETE CASCADE ON UPDATE CASCADE;
