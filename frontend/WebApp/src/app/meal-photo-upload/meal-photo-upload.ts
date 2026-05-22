import { CommonModule } from '@angular/common';
import { HttpErrorResponse, HttpClient } from '@angular/common/http';
import { ChangeDetectorRef, Component, ElementRef, EventEmitter, Input, OnDestroy, Output, ViewChild } from '@angular/core';
import { FormsModule } from '@angular/forms';

import { MealPhotoUploadService } from './meal-photo-upload.service';
import { LocalMealReviewResult } from './meal-photo-upload.types';
import { environment } from '../../environments/environment';

import { interval, Subscription } from 'rxjs';
import { switchMap, takeWhile } from 'rxjs/operators';

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

  // Tutaj jest miejsce na zmienne klasowe
  private pollingSub?: Subscription;

  constructor(
    private readonly uploadService: MealPhotoUploadService,
    private readonly changeDetector: ChangeDetectorRef,
    private readonly http: HttpClient // Dodany HttpClient
  ) {}

  get isLocked(): boolean {
    return this.loading || this.result !== null;
  }

  get isDebug(): boolean {
    return this.uploadService.isDebug;
  }

  // Połączone usuwanie URL i czyszczenie subskrypcji w jednym ngOnDestroy
  ngOnDestroy(): void {
    this.revokePreviewUrl();
    if (this.pollingSub) {
      this.pollingSub.unsubscribe();
    }
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

  uploadSelectedImage(): void {
    if (!this.selectedFile || !this.previewUrl || this.loading) {
      return;
    }
  }
}