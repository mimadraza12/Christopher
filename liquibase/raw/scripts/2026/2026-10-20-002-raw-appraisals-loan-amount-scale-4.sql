--liquibase formatted sql

--changeset imad.raza:2026-10-20-002-raw-appraisals-loan-amount-scale-4 labels:ddl
--comment: Loan_Amount Nullable(Decimal(18, 2)) -> Nullable(Decimal(18, 4)). Scale goes up (no precision lost), but the integer part shrinks from 16 to 14 digits (max 99,999,999,999,999.9999), so the precondition HALTS if any value would overflow. MODIFY COLUMN rewrites the column (a mutation); mutations_sync = 2 waits for it. Re-running is safe: modifying to the same type is a no-op. Rollback narrows back to 2 decimals and drops digits 3-4.
--preconditions onFail:HALT onError:HALT
--precondition-sql-check expectedResult:0 SELECT count() FROM raw.appraisals WHERE abs(Loan_Amount) >= toDecimal64(100000000000000, 2)
ALTER TABLE raw.appraisals
    MODIFY COLUMN Loan_Amount Nullable(Decimal(18, 4))
    SETTINGS mutations_sync = 2;
--rollback ALTER TABLE raw.appraisals MODIFY COLUMN Loan_Amount Nullable(Decimal(18, 2)) SETTINGS mutations_sync = 2;
