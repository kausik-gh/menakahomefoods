-- Menu item image storage and non-recursive menu policies.

INSERT INTO storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
VALUES (
  'menu-item-images',
  'menu-item-images',
  true,
  5242880,
  ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE
SET public = EXCLUDED.public,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

ALTER TABLE public.menu_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS menu_items_open_access ON public.menu_items;
DROP POLICY IF EXISTS menu_items_select_all ON public.menu_items;
DROP POLICY IF EXISTS menu_select ON public.menu_items;
DROP POLICY IF EXISTS menu_all_admin ON public.menu_items;
DROP POLICY IF EXISTS menu_items_admin_write ON public.menu_items;
DROP POLICY IF EXISTS menu_items_select_public ON public.menu_items;
DROP POLICY IF EXISTS menu_items_admin_insert ON public.menu_items;
DROP POLICY IF EXISTS menu_items_admin_update ON public.menu_items;
DROP POLICY IF EXISTS menu_items_admin_delete ON public.menu_items;

CREATE POLICY menu_items_select_public
ON public.menu_items
FOR SELECT
TO public
USING (true);

CREATE POLICY menu_items_admin_insert
ON public.menu_items
FOR INSERT
TO authenticated
WITH CHECK (public.current_user_is_admin());

CREATE POLICY menu_items_admin_update
ON public.menu_items
FOR UPDATE
TO authenticated
USING (public.current_user_is_admin())
WITH CHECK (public.current_user_is_admin());

CREATE POLICY menu_items_admin_delete
ON public.menu_items
FOR DELETE
TO authenticated
USING (public.current_user_is_admin());

DROP POLICY IF EXISTS menu_item_images_public_read ON storage.objects;
DROP POLICY IF EXISTS menu_item_images_admin_insert ON storage.objects;
DROP POLICY IF EXISTS menu_item_images_admin_update ON storage.objects;
DROP POLICY IF EXISTS menu_item_images_admin_delete ON storage.objects;

CREATE POLICY menu_item_images_admin_insert
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'menu-item-images'
  AND public.current_user_is_admin()
);

CREATE POLICY menu_item_images_admin_update
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'menu-item-images'
  AND public.current_user_is_admin()
)
WITH CHECK (
  bucket_id = 'menu-item-images'
  AND public.current_user_is_admin()
);

CREATE POLICY menu_item_images_admin_delete
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'menu-item-images'
  AND public.current_user_is_admin()
);
