-- Follow-up ACSU privacy and form-validation migration.
alter table public.membership_applications
  drop column if exists home_address,
  drop column if exists medical_notes;

alter table public.membership_applications
  add constraint membership_student_name_length check (char_length(student_full_name) between 1 and 120),
  add constraint membership_admission_length check (char_length(admission_number) between 1 and 40),
  add constraint membership_grade_length check (char_length(grade_class) between 1 and 40),
  add constraint membership_student_phone_length check (char_length(student_phone) between 1 and 32),
  add constraint membership_student_email_length check (char_length(student_email) between 3 and 254),
  add constraint membership_guardian_name_length check (char_length(guardian_name) between 1 and 120),
  add constraint membership_guardian_phone_length check (char_length(guardian_phone) between 1 and 32),
  add constraint membership_interest_length check (char_length(area_of_interest) between 1 and 80),
  add constraint membership_reason_length check (char_length(reason_for_joining) <= 1000);

alter table public.contact_messages
  add constraint contact_name_length check (char_length(full_name) between 1 and 100),
  add constraint contact_email_length check (char_length(email) between 3 and 254),
  add constraint contact_topic_length check (char_length(topic) between 1 and 80),
  add constraint contact_message_length check (char_length(message) between 5 and 4000);
