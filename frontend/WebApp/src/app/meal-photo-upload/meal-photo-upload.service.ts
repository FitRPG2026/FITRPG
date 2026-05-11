import { Injectable } from '@angular/core';

import { mealPhotoUploadConfig } from './meal-photo-upload.config';
import {
  LocalMealReviewResult,
  MealPhotoStorageName,
} from './meal-photo-upload.types';

@Injectable({ providedIn: 'root' })
export class MealPhotoUploadService {
  private readonly config = mealPhotoUploadConfig;

  createUnavailableMealReview(file: File, caption: string): LocalMealReviewResult {
    const createdAt = new Date();
    const storageName = this.createMealPhotoStorageName(file, createdAt);

    return {
      success: false,
      status: 503,
      message: 'Usługa tymczasowo niedostępna. Prosimy spróbować później.',
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

  private createMealPhotoStorageName(file: File, date: Date): MealPhotoStorageName {
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
