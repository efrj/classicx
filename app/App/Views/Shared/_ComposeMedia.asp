<input type="hidden" name="image_url" x-model="imageUrl">
<input type="file" x-ref="fileInput" name="image_file" accept="image/png,image/jpeg,image/webp,image/gif" class="x-file-input" @change="handleFileUpload($event)">

<div x-show="isUploading" x-cloak class="x-upload-status" role="status">
    <div class="spinner-border spinner-border-sm" aria-hidden="true"></div>
    <span>Uploading image to RustFS...</span>
</div>
<div x-show="uploadError" x-cloak class="x-upload-status x-upload-status-error" role="alert">
    <span class="x-upload-status-text" x-text="uploadError"></span>
    <button type="button" class="x-upload-dismiss" @click.prevent="dismissUploadError()" aria-label="Dismiss upload error">
        <i class="bi bi-x-lg" aria-hidden="true"></i>
    </button>
</div>

<template x-if="imageUrl">
    <div class="x-upload-preview">
        <img :src="imageUrl" alt="Image preview">
        <button type="button" @click.prevent="removeImage()" aria-label="Remove image" class="x-upload-remove">
            <i class="bi bi-x-lg" aria-hidden="true"></i>
        </button>
        <div class="x-upload-badge">
            <i class="bi bi-cloud-arrow-up" aria-hidden="true"></i> RustFS
        </div>
    </div>
</template>

<div x-show="showMediaInput" x-cloak class="mb-3">
    <div class="input-group input-group-sm">
        <span class="input-group-text bg-dark border-secondary text-secondary"><i class="bi bi-link-45deg" aria-hidden="true"></i></span>
        <input type="url" aria-label="Image URL" maxlength="255" class="form-control bg-dark text-white border-secondary" placeholder="Or paste image URL (e.g. https://...)" x-model="imageUrl">
    </div>
</div>
