DO $$
DECLARE
  u RECORD;
  codes jsonb;
  new_codes jsonb;
  c text;
  hashed text;
BEGIN
  FOR u IN SELECT id, mfa_recovery_codes FROM users WHERE mfa_recovery_codes IS NOT NULL AND mfa_recovery_codes != '' LOOP
    BEGIN
      codes := u.mfa_recovery_codes::jsonb;
      IF jsonb_typeof(codes) = 'array' THEN
        new_codes := '[]'::jsonb;
        FOR c IN SELECT jsonb_array_elements_text(codes) LOOP
          -- If already 64-char hex hash, keep as is (do not double-hash)
          IF length(c) = 64 AND c ~ '^[0-9a-fA-F]{64}$' THEN
            new_codes := new_codes || jsonb_build_array(lower(c));
          ELSE
            -- Normalize uppercase trimmed before hashing
            hashed := encode(sha256(upper(trim(c))::bytea), 'hex');
            new_codes := new_codes || jsonb_build_array(hashed);
          END IF;
        END LOOP;
        UPDATE users SET mfa_recovery_codes = new_codes::text WHERE id = u.id;
      END IF;
    EXCEPTION WHEN OTHERS THEN
      -- If JSON parsing fails for a corrupted row, skip safely
      NULL;
    END;
  END LOOP;
END $$;
