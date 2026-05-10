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

The route above is only a local preview entry point. The component itself can be reused elsewhere with:

```html
<app-meal-photo-upload></app-meal-photo-upload>
```

## Current local behavior

- Clicking or dragging into the upload area selects an image.
- After selecting an image, the upload area turns into the selected image preview.
- Clicking the image before sending lets the user choose a different image.
- Cancelling the file picker keeps the previous image.
- After clicking `Załaduj zdjęcie`, the image picker and caption field are locked.
- After 10 seconds, the component shows: `Usługa tymczasowo niedostępna. Prosimy spróbować później.`
- The UI does not display the JSON payload.

## API payload mock

Until Cloudinary/backend integration is available, the component creates a local mock result and emits it through `mealReviewCreated`.

The mock payload contains `meal_review` with:

- generated image name
- creation date
- caption
- empty `url`
- Cloudinary-oriented storage naming metadata

Cloudinary naming convention used by the mock:

```text
asset_folder: fitrpg/{env}/users/{userId}/meals/{YYYY}/{MM}
public_id: meal-{YYYYMMDDTHHMMSSZ}-{shortId}
```
