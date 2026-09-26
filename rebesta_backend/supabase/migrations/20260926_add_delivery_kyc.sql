-- ============================================================
-- Rider KYC: document upload + verification flow
-- ============================================================
--
-- Run this in the Supabase SQL editor (Dashboard -> SQL Editor).
--
-- Flow:
--   1. Rider uploads 4 documents (Aadhaar front/back, driving
--      license, selfie) from the rider app.
--   2. When all 4 exist, kyc_status flips to 'submitted'.
--   3. Admin reviews (GET /admin/delivery-kyc) and approves
--      or rejects with a reason.
--   4. Rider sees the status + rejection reason in the app.
--
-- Documents are stored in a PRIVATE storage bucket (KYC docs
-- are PII - never public). The backend hands out short-lived
-- signed URLs only to the owning rider and to admins.
--
-- Until this migration runs, the KYC endpoints return errors
-- but nothing else breaks (no existing query touches these
-- columns).
-- ============================================================

-- ------------------------------------------------------------
-- 1. KYC status on the partner
-- ------------------------------------------------------------

alter table public.delivery_partners
  add column if not exists kyc_status text
    not null default 'pending'
    check (
      kyc_status in (
        'pending',
        'submitted',
        'verified',
        'rejected'
      )
    );

alter table public.delivery_partners
  add column if not exists kyc_rejection_reason text;

-- ------------------------------------------------------------
-- 2. Documents (one row per document type per rider;
--    re-uploading replaces the previous file)
-- ------------------------------------------------------------

create table if not exists public.delivery_kyc_documents (
  id uuid primary key default gen_random_uuid(),

  delivery_partner_id uuid not null
    references public.delivery_partners(id)
    on delete cascade,

  document_type text not null
    check (
      document_type in (
        'aadhaar_front',
        'aadhaar_back',
        'driving_license',
        'selfie'
      )
    ),

  storage_path text not null,

  created_at timestamptz not null default now(),

  unique (delivery_partner_id, document_type)
);

create index if not exists idx_delivery_kyc_documents_partner
  on public.delivery_kyc_documents(delivery_partner_id);

-- ------------------------------------------------------------
-- 3. Private storage bucket for the documents
-- ------------------------------------------------------------

insert into storage.buckets (id, name, public)
values ('kyc-documents', 'kyc-documents', false)
on conflict (id) do nothing;
