import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { firstValueFrom } from 'rxjs';

import { mealPhotoUploadConfig } from './meal-photo-upload.config';
import {
  CloudinaryUploadResponse,
  LocalMealReviewResult,
  MealPhotoMetadata,
  MealPhotoStorageName,
} from './meal-photo-upload.types';

@Injectable({ providedIn: 'root' })
export class MealPhotoUploadService {
  private readonly config = mealPhotoUploadConfig;

  constructor(private readonly http: HttpClient) {}

  get isDebug(): boolean {
    return this.config.isDebug === 1;
  }

  async uploadMealPhoto(
    file: File,
    caption: string,
    userId: string | number = this.config.defaultUserId,
    mealTitle = '',
  ): Promise<LocalMealReviewResult> {
    if (!this.config.cloudinaryCloudName || !this.config.cloudinaryUploadPreset) {
      throw new Error('Brakuje cloud name albo upload preset dla Cloudinary.');
    }

    const createdAt = new Date();
    const metadata = this.createMealPhotoMetadata(mealTitle, caption);
    const storageName = this.createMealPhotoStorageName(
      file,
      createdAt,
      this.slugify(String(userId)) || this.config.defaultUserId,
      metadata.meal_title,
    );
    const uploadFile = await this.compressImageIfNeeded(file);
    const cloudinaryResponse = await this.uploadToCloudinary(uploadFile, storageName, metadata);

    return {
      success: true,
      status: 201,
      message: 'Zdjęcie posiłku zostało wysłane.',
      meal_review: {
        image_name: cloudinaryResponse.public_id || storageName.public_id,
        created_at: cloudinaryResponse.created_at || createdAt.toISOString(),
        caption: metadata.notes,
        url: cloudinaryResponse.secure_url,
        rating: null,
        storage: storageName,
        metadata,
      },
    };
  }

  private async uploadToCloudinary(
    file: File | Blob,
    storageName: MealPhotoStorageName,
    metadata: MealPhotoMetadata,
  ): Promise<CloudinaryUploadResponse> {
    const formData = new FormData();
    formData.append('file', file);
    formData.append('upload_preset', this.config.cloudinaryUploadPreset);
    formData.append('folder', storageName.asset_folder);
    formData.append('public_id', storageName.public_id);
    formData.append('context', this.createContextMetadata(metadata));

    const url = `https://api.cloudinary.com/v1_1/${this.config.cloudinaryCloudName}/image/upload`;
    return firstValueFrom(this.http.post<CloudinaryUploadResponse>(url, formData));
  }

  private async compressImageIfNeeded(file: File): Promise<File | Blob> {
    if (!file.type.startsWith('image/')) {
      return file;
    }

    const shouldNormalizeFormat = !['image/jpeg', 'image/png', 'image/webp'].includes(file.type);
    const image = await this.loadImage(file);
    const targetWidth = Math.min(image.naturalWidth, this.config.maxImageWidth);
    const targetHeight = Math.round((image.naturalHeight * targetWidth) / image.naturalWidth);
    const shouldResize = image.naturalWidth > this.config.maxImageWidth;

    if (!shouldResize && !shouldNormalizeFormat && file.size <= this.config.compressionThresholdBytes) {
      return file;
    }

    const canvas = document.createElement('canvas');
    canvas.width = targetWidth;
    canvas.height = targetHeight;

    const context = canvas.getContext('2d');
    if (!context) {
      return file;
    }

    context.drawImage(image, 0, 0, targetWidth, targetHeight);
    const compressedBlob = await new Promise<Blob | null>((resolve) => {
      canvas.toBlob(resolve, 'image/jpeg', this.config.imageQuality);
    });

    if (!compressedBlob || compressedBlob.size >= file.size) {
      return file;
    }

    return new File([compressedBlob], this.replaceExtension(file.name, 'jpg'), {
      type: 'image/jpeg',
      lastModified: file.lastModified,
    });
  }

  private loadImage(file: File): Promise<HTMLImageElement> {
    return new Promise((resolve, reject) => {
      const url = URL.createObjectURL(file);
      const image = new Image();

      image.onload = () => {
        URL.revokeObjectURL(url);
        resolve(image);
      };
      image.onerror = () => {
        URL.revokeObjectURL(url);
        reject(new Error('Nie udalo sie odczytac obrazu.'));
      };
      image.src = url;
    });
  }

  private createMealPhotoStorageName(file: File, date: Date, userId: string, mealTitle: string): MealPhotoStorageName {
    const year = String(date.getUTCFullYear());
    const month = String(date.getUTCMonth() + 1).padStart(2, '0');
    const timestamp = date.toISOString()
      .replace(/[-:]/g, '')
      .replace(/\.\d{3}Z$/, 'Z');
    const suffix = this.createShortId();
    const originalBaseName = this.stripExtension(file.name);
    const safeOriginalName = this.slugify(originalBaseName) || 'photo';
    const safeMealTitle = this.slugify(mealTitle) || safeOriginalName || 'meal';
    const publicId = `meal-${safeMealTitle}-${timestamp}-${suffix}`;
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
      display_name: publicId,
      original_file_name: file.name,
    };
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

  private replaceExtension(fileName: string, extension: string): string {
    return `${this.stripExtension(fileName) || 'photo'}.${extension}`;
  }

  private createMealPhotoMetadata(mealTitle: string, notes: string): MealPhotoMetadata {
    const normalizedTitle = mealTitle.trim();
    const normalizedNotes = notes.trim();
    const fallbackDescription = normalizedTitle || normalizedNotes || 'Zdjęcie posiłku';

    return {
      meal_title: normalizedTitle,
      notes: normalizedNotes,
      caption: normalizedNotes || fallbackDescription,
      alt: fallbackDescription,
    };
  }

  private createContextMetadata(metadata: MealPhotoMetadata): string {
    return Object.entries(metadata)
      .filter(([, value]) => value.trim().length > 0)
      .map(([key, value]) => `${key}=${this.escapeContextValue(value)}`)
      .join('|');
  }

  private escapeContextValue(value: string): string {
    return value
      .replace(/\\/g, '\\\\')
      .replace(/\|/g, '\\|')
      .replace(/=/g, '\\=');
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
