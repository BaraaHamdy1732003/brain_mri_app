# brain_mri_app
# brain_mri_app

Flutter app for brain MRI classification with Supabase and a TFLite model.

## Setup
1. Put your TFLite model at `assets/model/brain_mri_4class_balanced_model.tflite`.
2. Put your labels (one per line, in correct order) in `assets/model/labels.txt`.
3. Fill Supabase URL and anon key in `lib/utils/constants.dart`.
4. Create Supabase storage bucket `predictions` and table `predictions`:
   - id uuid primary key (or text)
   - user_id text
   - image_url text
   - predicted_label text
   - scores jsonb
   - created_at timestamp default now()
5. Run:
supabase pass :1710701732003