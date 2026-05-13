# Meal photo upload

Reusable Angular component for adding a meal photo with an optional caption.

## How to view it locally

Run the frontend:

```powershell
cd frontend/WebApp
npm.cmd start
```

Open:

```text
http://localhost:4200/meal-upload
```

The route above is a local preview entry point and uses Anna Nowak's seeded user id (`1`) by default. The component itself can be reused elsewhere with:

```html
<app-meal-photo-upload></app-meal-photo-upload>
```

When the target screen already knows the current user, pass that id explicitly:

```html
<app-meal-photo-upload [userId]="currentUserId"></app-meal-photo-upload>
```

## Integration notes

- The preview route `/meal-upload` is not protected by login and intentionally uses `defaultUserId: 1`.
- In a real logged-in screen, the parent page should handle authentication and pass the logged-in user's id through `[userId]`.
- If `[userId]` is not passed, uploads are stored under Anna Nowak's seeded user id (`1`).
- The component does not read the auth token and does not save anything to the backend/database.

## Cloudinary setup

The component uploads directly from the browser using this unsigned preset:

```text
cloud_name: dxdmkv4bt
upload_preset: fitrpg_meals_unsigned
```

If your Cloudinary cloud name is different, update `meal-photo-upload.config.ts`.

The default user id is configured in `meal-photo-upload.config.ts`:

```text
defaultUserId: 1
```

Debug output is controlled in `meal-photo-upload.config.ts`:

```text
isDebug: 0
```

- `isDebug: 0` shows only the short user-facing success message.
- `isDebug: 1` also shows the Cloudinary `secure_url` and photo description on `/meal-upload`.

The frontend sends `folder` and `public_id` in the Cloudinary upload request:

```text
folder: fitrpg/local/users/{userId}/meals/{YYYY}/{MM}
public_id: meal-{YYYYMMDDTHHMMSSZ}-{shortId}
context: caption={caption}|alt={caption}
```

If uploaded files still appear in `Home`, edit the unsigned preset in Cloudinary and set its asset folder/folder to `fitrpg/local/meals` or allow folder values from the upload request.

## Current local behavior

- Clicking or dragging into the upload area selects an image.
- After selecting an image, the upload area turns into the selected image preview.
- Clicking the image before sending lets the user choose a different image.
- Cancelling the file picker keeps the previous image.
- After clicking `Zaladuj zdjecie`, the image picker and caption field are locked.
- Files above 1 MB, images wider than 1080 px, and non-web photo formats such as BMP are converted in the browser to JPEG quality 80% before upload.
- The component sends the image only to Cloudinary and reads `secure_url`.
- Nothing is saved to the backend/database by this component.
- The UI does not display the JSON payload.

Cloudinary naming convention still generated locally for emitted metadata:

```text
asset_folder: fitrpg/{env}/users/{userId}/meals/{YYYY}/{MM}
public_id: meal-{YYYYMMDDTHHMMSSZ}-{shortId}
```
