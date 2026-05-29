import { CommonModule } from '@angular/common';
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
  @Input() showCaption = true;
  @Input() showUploadButton = true;
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
    if (this.isLocked) return;
    this.fileInput?.nativeElement.click();
  }

  onDragOver(event: DragEvent): void {
    event.preventDefault();
    if (this.isLocked) return;
    this.dragging = true;
  }

  onDragLeave(event: DragEvent): void {
    event.preventDefault();
    this.dragging = false;
  }

  onDrop(event: DragEvent): void {
    event.preventDefault();
    this.dragging = false;

    if (this.isLocked) return;

    const file = event.dataTransfer?.files?.[0] ?? null;
    if (!file) return;

    this.setSelectedFile(file);
  }

  get hasSelectedImage(): boolean {
    return this.selectedFile !== null;
  }

  async uploadSelectedImage(): Promise<LocalMealReviewResult | null> {
    if (this.result) {
      return this.result;
    }

    if (!this.selectedFile || !this.previewUrl || this.loading) {
      return null;
    }

    this.loading = true;
    this.errorMessage = null;
    this.statusMessage = null;

    try {
      const result = await this.uploadService.uploadMealPhoto(
        this.selectedFile,
        this.caption.trim(),
        this.userId,
      );

      this.result = result;
      this.statusMessage = result.message;
      this.mealReviewCreated.emit(result);
      return result;
    } catch (error) {
      this.errorMessage = error instanceof Error
        ? error.message
        : 'Nie udało się wysłać zdjęcia posiłku.';
      return null;
    } finally {
      this.loading = false;
      this.changeDetector.markForCheck();
    }
  }
  private setSelectedFile(file: File): void {
    this.revokePreviewUrl();
    this.selectedFile = file;
    this.previewUrl = URL.createObjectURL(file);
  }

  private revokePreviewUrl(): void {
    if (this.previewUrl) {
      URL.revokeObjectURL(this.previewUrl);
      this.previewUrl = null;
    }
  }

  // Obsługa zmiany tekstu w HTML
  onCaptionChange(event: string): void {
    this.caption = event;
  }

  // Blokowanie edycji pola (np. podczas ładowania)
  blockCaptionEdit(event: Event): void {
    if (this.isLocked) {
      event.preventDefault();
    }
  }
}
