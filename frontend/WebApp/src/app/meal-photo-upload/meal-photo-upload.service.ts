import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, of, switchMap } from 'rxjs';
import { delay, map } from 'rxjs/operators';

import { mealPhotoUploadConfig } from './meal-photo-upload.config';
import {
  BackendMealImageResult,
  CloudinaryUploadResponse,
  LocalMealReviewResult,
  MealImagePayload,
  MealImageResult,
  MealPhotoStorageName,
} from './meal-photo-upload.types';

@Injectable({ providedIn: 'root' })
export class MealPhotoUploadService {
  private readonly config = mealPhotoUploadConfig;

  constructor(private readonly http: HttpClient) {}

  uploadMealImage(file: File): Observable<MealImageResult> {
    if (this.config.useLocalMock) {
      return this.uploadMealImageLocally(file);
    }

    return this.uploadMealImageToCloudinary(file);
  }

  saveMealImageUrl(imageUrl: string): Observable<BackendMealImageResult> {
    if (this.config.useLocalMock) {
      return this.saveMealImageUrlLocally(imageUrl);
    }

    const payload: MealImagePayload = { image_url: imageUrl };
    return this.http.post<BackendMealImageResult>(
      `${this.config.backendBaseUrl}/api/meals`,
      payload,
    );
  }

  uploadAndSaveMealImage(file: File): Observable<BackendMealImageResult> {
    return this.uploadMealImage(file).pipe(
      switchMap((uploadResult) => this.saveMealImageUrl(uploadResult.imageUrl)),
    );
  }

  createLocalMealReview(file: File, caption: string, blobUrl: string): Observable<LocalMealReviewResult> {
    return of(this.createLocalMealReviewPayload(file, caption, blobUrl)).pipe(delay(10000));
  }

  createImmediateLocalMealReview(file: File, caption: string, blobUrl: string): Observable<LocalMealReviewResult> {
    return of(this.createLocalMealReviewPayload(file, caption, blobUrl));
  }

  createLocalMealReviewPayload(file: File, caption: string, blobUrl: string): LocalMealReviewResult {
    const createdAt = new Date();
    const storageName = this.createMealPhotoStorageName(file, createdAt);

    return {
      success: false,
      status: 503,
      message: 'Usługa tymczasowo niedostępna. Prosimy spróbować później.',
      blob_url: blobUrl,
      meal_review: {
        image_name: storageName.public_id,
        created_at: createdAt.toISOString(),
        caption,
        url: '',
        rating: null,
        storage: storageName,
      },
    };
  }

  private uploadMealImageToCloudinary(file: File): Observable<MealImageResult> {
    this.assertCloudinaryConfig();

    const formData = new FormData();
    formData.append('file', file);
    formData.append('upload_preset', this.config.uploadPreset);

    const storageName = this.createMealPhotoStorageName(file);
    formData.append('asset_folder', storageName.asset_folder);
    formData.append('public_id_prefix', storageName.public_id_prefix);
    formData.append('public_id', storageName.public_id);
    formData.append('display_name', storageName.display_name);

    return this.http
      .post<CloudinaryUploadResponse>(
        `https://api.cloudinary.com/v1_1/${this.config.cloudName}/image/upload`,
        formData,
      )
      .pipe(
        map((response) => ({
          imageUrl: response.secure_url,
          localOnly: false,
        })),
      );
  }

  private uploadMealImageLocally(file: File): Observable<MealImageResult> {
    const localUrl = URL.createObjectURL(file);

    return of({
      imageUrl: localUrl,
      localOnly: true,
    }).pipe(delay(400));
  }

  private saveMealImageUrlLocally(imageUrl: string): Observable<BackendMealImageResult> {
    return of({
      success: true,
      image_url: imageUrl,
      localOnly: true,
    }).pipe(delay(300));
  }

  private assertCloudinaryConfig(): void {
    if (!this.config.cloudName || !this.config.uploadPreset) {
      throw new Error('Cloudinary cloudName and uploadPreset are required.');
    }
  }

  private createMealPhotoStorageName(file: File, date = new Date()): MealPhotoStorageName {
    const userId = this.getCurrentUserId();
    const year = String(date.getUTCFullYear());
    const month = String(date.getUTCMonth() + 1).padStart(2, '0');
    const timestamp = date.toISOString()
      .replace(/[-:]/g, '')
      .replace(/\.\d{3}Z$/, 'Z');
    const suffix = this.createShortId();
    const originalBaseName = this.stripExtension(file.name);
    const safeOriginalName = this.slugify(originalBaseName) || 'photo';
    const publicId = `meal-${timestamp}-${suffix}`;
    const folder = [
      this.slugify(this.config.storageRoot) || 'fitrpg',
      this.slugify(this.config.storageEnvironment) || 'local',
      'users',
      userId,
      'meals',
      year,
      month,
    ].join('/');

    return {
      asset_folder: folder,
      public_id: publicId,
      public_id_prefix: folder,
      display_name: `${safeOriginalName}-${publicId}`,
      original_file_name: file.name,
    };
  }

  private getCurrentUserId(): string {
    if (typeof window === 'undefined') {
      return 'server';
    }

    return this.slugify(localStorage.getItem('user_id') || 'local-user');
  }

  private createShortId(): string {
    if (typeof crypto !== 'undefined' && 'randomUUID' in crypto) {
      return crypto.randomUUID().slice(0, 8);
    }

    return Math.random().toString(36).slice(2, 10);
  }

  private stripExtension(fileName: string): string {
    return fileName.replace(/\.[^/.]+$/, '');
  }

  private slugify(value: string): string {
    return value
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '')
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/^-+|-+$/g, '');
  }
}
