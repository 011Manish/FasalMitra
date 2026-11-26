-- Add new crop types to the crop_type enum.
-- Kept in its own migration: a new enum value cannot be used in the same
-- transaction that adds it, so the crop_rules inserts live in the next file.

alter type public.crop_type add value if not exists 'potato';
alter type public.crop_type add value if not exists 'tomato';
alter type public.crop_type add value if not exists 'cauliflower';
alter type public.crop_type add value if not exists 'onion';
alter type public.crop_type add value if not exists 'millet';
alter type public.crop_type add value if not exists 'lentil';