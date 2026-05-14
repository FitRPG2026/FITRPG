import { CommonModule } from '@angular/common';
import { HttpErrorResponse } from '@angular/common/http';
import { ChangeDetectorRef, Component, ElementRef, EventEmitter, Input, OnDestroy, Output, ViewChild } from '@angular/core';
import { FormsModule } from '@angular/forms';

import { MealPhotoUploadService } from './meal-photo-upload.service';
import { LocalMealReviewResult } from './meal-photo-upload.types';

@Component({
  selector: 'app-meal-photo-upload',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './meal-photo-upload.html',
  styleUrl: './meal-photo-upload.css',
})
export class MealPhotoUploadComponent implements OnDestroy {
  @Input() userId: string | number = '1';
  @Output() mealReviewCreated = new EventEmitter<LocalMealReviewResult>();
  @ViewChild('captionInput') private captionInput?: ElementRef<HTMLTextAreaElement>;
  @ViewChild('fileInput') private fileInput?: ElementRef<HTMLInputElement>;

  selectedFile: File | null = null;
  previewUrl: string | null = null;
  caption = '';
  result: LocalMealReviewResult | null = null;
  statusMessage: string | null = null;
  loading = false;
  dragging = false;
  errorMessage: string | null = null;

  constructor(
    private readonly uploadService: MealPhotoUploadService,
    private readonly changeDetector: ChangeDetectorRef,
  ) {}

  get isLocked(): boolean {
    return this.loading || this.result !== null;
  }

  get isDebug(): boolean {
    return this.uploadService.isDebug;
  }

  ngOnDestroy(): void {
    this.revokePreviewUrl();
  }

  onFileSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0] ?? null;

    if (this.isLocked) {
      input.value = '';
      return;
    }

    if (!file) {
      return;
    }

    this.setSelectedFile(file);
  }

  openFilePicker(event: Event): void {
    event.preventDefault();

    if (this.isLocked) {
      return;
    }

    this.fileInput?.nativeElement.click();
  }

  onDragOver(event: DragEvent): void {
    event.preventDefault();
    if (this.isLocked) {
      return;
    }

    this.dragging = true;
  }

  onDragLeave(event: DragEvent): void {
    event.preventDefault();
    this.dragging = false;
  }

  onDrop(event: DragEvent): void {
    event.preventDefault();
    this.dragging = false;

    if (this.isLocked) {
      return;
    }

    const file = event.dataTransfer?.files?.[0] ?? null;
    if (!file) {
      return;
    }

    this.setSelectedFile(file);
  }

  uploadSelectedImage(): void {
    if (!this.selectedFile || !this.previewUrl || this.loading) {
      return;
    }

    const file = this.selectedFile;
    const caption = this.caption.trim();

    this.loading = true;
    this.errorMessage = null;
    this.result = null;
    this.statusMessage = null;
    this.captionInput?.nativeElement.blur();
    console.log('mealPhotoUpload submit started', {
      file_name: file.name,
      caption,
    });

    this.uploadService.uploadMealPhoto(file, caption, this.userId)
      .then((result) => {
        this.loading = false;
        this.result = result;
        this.statusMessage = result.message;
        console.log('mealReviewCreated', result);
        this.mealReviewCreated.emit(result);
        this.changeDetector.detectChanges();
      })
      .catch((error: unknown) => {
        this.loading = false;
        this.errorMessage = this.resolveErrorMessage(error);
        this.changeDetector.detectChanges();
      });
  }

  onCaptionChange(value: string): void {
    if (this.isLocked) {
      return;
    }

    this.caption = value;
  }

  blockCaptionEdit(event: Event): void {
    if (this.isLocked) {
      event.preventDefault();
      const input = this.captionInput?.nativeElement;
      if (input) {
        input.value = this.caption;
        input.blur();
      }
    }
  }

  private setSelectedFile(file: File): void {
    this.resetResult();
    this.revokePreviewUrl();
    this.selectedFile = file;

    if (!file.type.startsWith('image/')) {
      this.selectedFile = null;
      this.previewUrl = null;
      this.errorMessage = 'Wybierz plik obrazu.';
      return;
    }

    this.previewUrl = URL.createObjectURL(file);
  }

  private resetResult(): void {
    this.result = null;
    this.statusMessage = null;
    this.errorMessage = null;
  }

  private resolveErrorMessage(error: unknown): string {
    if (error instanceof HttpErrorResponse) {
      if (error.status === 0) {
        return 'Cloudinary nie odpowiedziało. Sprawdź upload preset i połączenie z internetem.';
      }

      const cloudinaryMessage = error.error?.error?.message || error.error?.message;
      return cloudinaryMessage || `Cloudinary odrzuciło upload. Status: ${error.status}.`;
    }

    if (error instanceof Error) {
      return error.message;
    }

    return 'Nie udało się wysłać zdjęcia. Spróbuj ponownie.';
  }

  private revokePreviewUrl(): void {
    if (this.previewUrl) {
      URL.revokeObjectURL(this.previewUrl);
      this.previewUrl = null;
    }
  }
}

