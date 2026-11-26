# Adding and editing tutorial videos

Run these in the Supabase dashboard, SQL Editor. Only add videos that the client owns,
has permission to use, or that the platform allows to be embedded. Never download or
re-upload a video.

## Add a video
```sql
insert into public.learning_content
  (content_type, title, summary, body, category, language, external_url, thumbnail_url)
values
  ('video', '<title>', '<one line description>', '', '<category>', '<language>',
   '<https video link>', null);
```
- category: general, vegetable_farming, rice, maize, soil_testing, compost_fertilizer,
  irrigation, pest_disease, harvesting_selling
- language: ne (Nepali), en (English), hi (Hindi)
- Leave thumbnail_url as null for YouTube links. The app uses YouTube's own picture.
  For other links, paste an https image link you may use.

## Edit a video
```sql
update public.learning_content
set title = '<new title>', external_url = '<new https link>'
where id = '<video id>';
```

## Delete a video
First check what you are deleting:
```sql
select id, title from public.learning_content where id = '<video id>';
```
Only then:
```sql
delete from public.learning_content where id = '<video id>';
```

## Third-party services (list in the handover)
YouTube: videos play through the YouTube player and thumbnails load from YouTube's
image servers (img.youtube.com).