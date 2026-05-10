import { CommonModule } from '@angular/common';
import { ChangeDetectorRef, Component, ElementRef, EventEmitter, OnDestroy, Output, ViewChild } from '@angular/core';
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
  private fallbackTimerId: ReturnType<typeof setTimeout> | null = null;

  constructor(
    private readonly uploadService: MealPhotoUploadService,
    private readonly changeDetector: ChangeDetectorRef,
  ) {}

  get isLocked(): boolean {
    return this.loading || this.result !== null;
  }

  ngOnDestroy(): void {
    this.clearUnavailableFallback();
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

    this.loading = true;
    this.errorMessage = null;
    this.result = null;
    this.statusMessage = null;
    this.captionInput?.nativeElement.blur();
    this.startUnavailableFallback();
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
    this.clearUnavailableFallback();
    this.result = null;
    this.statusMessage = null;
    this.errorMessage = null;
  }

  private startUnavailableFallback(): void {
    this.clearUnavailableFallback();

    const file = this.selectedFile;
    if (!file || !this.previewUrl) {
      return;
    }

    const caption = this.caption.trim();

    this.fallbackTimerId = setTimeout(() => {
      const result = this.uploadService.createUnavailableMealReview(file, caption);

      this.fallbackTimerId = null;
      this.loading = false;
      this.result = result;
      this.statusMessage = result.message;
      this.mealReviewCreated.emit(result);
      this.changeDetector.detectChanges();
    }, 10000);
  }

  private clearUnavailableFallback(): void {
    if (this.fallbackTimerId) {
      clearTimeout(this.fallbackTimerId);
      this.fallbackTimerId = null;
    }
  }

  private revokePreviewUrl(): void {
    if (this.previewUrl) {
      URL.revokeObjectURL(this.previewUrl);
      this.previewUrl = null;
    }
  }
}
