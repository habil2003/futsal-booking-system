-- AlterTable
ALTER TABLE "Futsal" ADD COLUMN     "registrationFeePaid" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "registrationPaidAt" TIMESTAMP(3);

-- AlterTable
ALTER TABLE "SystemSettings" ADD COLUMN     "registrationFeeAmount" DOUBLE PRECISION NOT NULL DEFAULT 500.0,
ADD COLUMN     "registrationFeeEnabled" BOOLEAN NOT NULL DEFAULT false;
