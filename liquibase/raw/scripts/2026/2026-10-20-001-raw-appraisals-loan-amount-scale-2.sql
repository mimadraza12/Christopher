--liquibase formatted sql

--changeset imad.raza:2026-10-20-001-raw-appraisals-loan-amount-scale-2 labels:ddl
--comment: Loan_Amount Nullable(Decimal(18, 3)) -> Nullable(Decimal(18, 2)), reverting 2026-10-19-001. Narrowing the scale drops the third decimal, so the precondition HALTS if any row has a non-zero third decimal (to accept that loss, change the check deliberately in a reviewed PR). MODIFY COLUMN rewrites the column (a mutation); mutations_sync = 2 waits for it. Re-running is safe: modifying to the same type is a no-op.
--preconditions onFail:HALT onError:HALT
--precondition-sql-check expectedResult:0 SELECT count() FROM raw.appraisals WHERE Loan_Amount IS NOT NULL AND toDecimal64(Loan_Amount, 3) != toDecimal64(toDecimal64(Loan_Amount, 2), 3)
ALTER TABLE raw.appraisals
    MODIFY COLUMN Loan_Amount Nullable(Decimal(18, 2))
    SETTINGS mutations_sync = 2;
--rollback ALTER TABLE raw.appraisals MODIFY COLUMN Loan_Amount Nullable(Decimal(18, 3)) SETTINGS mutations_sync = 2;
