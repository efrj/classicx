const IMAGE_TYPES = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
const IMAGE_EXTS = ['jpg', 'jpeg', 'png', 'gif', 'webp'];

function imageFileError(file) {
    if (!file) return 'Please select an image.';
    const ext = (file.name.split('.').pop() || '').toLowerCase();
    const typeOk = IMAGE_TYPES.includes(file.type) || (file.type === '' && IMAGE_EXTS.includes(ext));
    if (!typeOk) return 'Please select a valid image (PNG, JPG, GIF, WEBP).';
    if (file.size > 10 * 1024 * 1024) return 'Image must be smaller than 10MB.';
    return '';
}

async function uploadImageToRustFs(file) {
    const problem = imageFileError(file);
    if (problem) throw new Error(problem);
    const formData = new FormData();
    formData.append('image_file', file);
    formData.append('csrf_token', document.querySelector('meta[name="csrf-token"]')?.content || '');
    const response = await fetch('/tweets/upload', {method: 'POST', body: formData});
    const raw = await response.text();
    let data = {};
    try {
        data = raw ? JSON.parse(raw) : {};
    } catch (parseError) {
        throw new Error('Upload failed.');
    }
    if (!response.ok || !data.success || !(data.url || data.relative_url)) {
        throw new Error(data.error || 'Failed to upload image to RustFS');
    }
    return data.url || data.relative_url;
}

async function writeAction(url, values) {
    const data = new URLSearchParams(values);
    data.set('csrf_token', document.querySelector('meta[name="csrf-token"]').content);
    const response = await fetch(url, {method: 'POST', body: data});
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    const result = await response.json();
    if (typeof result.active !== 'boolean') throw new Error('Invalid response');
    return result.active;
}

/**
 * ClassicX - Alpine.js micro-reactivity and client interactions
 */

document.addEventListener('alpine:init', () => {
    // Tweet composer component with RustFS uploads
    Alpine.data('composeBox', () => ({
        content: '',
        imageUrl: '',
        showMediaInput: false,
        isUploading: false,
        uploadError: '',
        maxChars: 280,

        get charCount() {
            return this.content.length;
        },
        get charsRemaining() {
            return this.maxChars - this.content.length;
        },
        get isValid() {
            return this.content.trim().length > 0 && this.content.length <= this.maxChars && !this.isUploading;
        },
        get progressPercent() {
            return Math.min(100, (this.content.length / this.maxChars) * 100);
        },
        get progressColor() {
            if (this.charsRemaining < 0) return '#f4212e';
            if (this.charsRemaining <= 20) return '#ffd400';
            return '#1d9bf0';
        },
        autoExpand(e) {
            e.target.style.height = 'auto';
            e.target.style.height = (e.target.scrollHeight) + 'px';
        },
        toggleMedia() {
            this.showMediaInput = !this.showMediaInput;
        },
        dismissUploadError() {
            this.uploadError = '';
        },
        triggerFileInput() {
            if (this.$refs.fileInput) {
                this.$refs.fileInput.click();
            }
        },
        prepareSubmit(event) {
            if (this.isUploading) {
                event.preventDefault();
                return;
            }
            const hidden = event.target.querySelector('input[name="image_url"]');
            if (hidden) hidden.value = this.imageUrl || '';
        },
        async handleFileUpload(event) {
            const file = event.target.files && event.target.files[0];
            if (!file) return;

            const problem = imageFileError(file);
            if (problem && problem !== 'Please select an image.') {
                this.imageUrl = '';
                this.uploadError = problem;
                showXToast(this.uploadError);
                event.target.value = '';
                return;
            }

            this.isUploading = true;
            this.uploadError = '';

            try {
                this.imageUrl = await uploadImageToRustFs(file);
                const hidden = event.target.form && event.target.form.querySelector('input[name="image_url"]');
                if (hidden) hidden.value = this.imageUrl;
                showXToast('Image uploaded to RustFS');
            } catch (err) {
                console.error('RustFS upload failed:', err);
                this.imageUrl = '';
                this.uploadError = err.message || 'Error uploading to RustFS';
                showXToast(this.uploadError);
            } finally {
                this.isUploading = false;
                event.target.value = '';
            }
        },
        removeImage() {
            this.imageUrl = '';
            this.uploadError = '';
            if (this.$refs.fileInput) {
                this.$refs.fileInput.value = '';
            }
        }
    }));

    Alpine.data('profileEditor', () => ({
        bannerUrl: '',
        avatarUrl: '',
        uploading: '',
        uploadError: '',
        bioCount: 0,
        maxBio: 160,

        init() {
            const banner = this.$el.querySelector('input[name="banner_url"]');
            const avatar = this.$el.querySelector('input[name="avatar_url"]');
            const bio = this.$el.querySelector('#profileBioInput');
            this.bannerUrl = banner ? banner.value : '';
            this.avatarUrl = avatar ? avatar.value : '';
            this.bioCount = bio ? bio.value.length : 0;
        },
        get bannerStyle() {
            if (!this.bannerUrl) return '';
            const safe = String(this.bannerUrl).replace(/["'\\()]/g, '');
            return `background-image:url('${safe}')`;
        },
        dismissUploadError() {
            this.uploadError = '';
        },
        pick(kind) {
            const input = this.$refs[kind + 'File'];
            if (input && !this.uploading) input.click();
        },
        prepareSubmit(event) {
            if (this.uploading) {
                event.preventDefault();
                return;
            }
            const banner = event.target.querySelector('input[name="banner_url"]');
            const avatar = event.target.querySelector('input[name="avatar_url"]');
            if (banner) banner.value = this.bannerUrl || '';
            if (avatar) avatar.value = this.avatarUrl || '';
        },
        async upload(kind, event) {
            const file = event.target.files && event.target.files[0];
            event.target.value = '';
            if (!file) return;
            const problem = imageFileError(file);
            if (problem) {
                this.uploadError = problem;
                showXToast(problem);
                return;
            }
            this.uploading = kind;
            this.uploadError = '';
            try {
                const url = await uploadImageToRustFs(file);
                const input = this.$el.querySelector(`input[name="${kind}_url"]`);
                if (kind === 'banner') this.bannerUrl = url;
                else this.avatarUrl = url;
                if (input) input.value = url;
                showXToast('Image uploaded to RustFS');
            } catch (err) {
                console.error('RustFS upload failed:', err);
                this.uploadError = err.message || 'Error uploading to RustFS';
                showXToast(this.uploadError);
            } finally {
                this.uploading = '';
            }
        }
    }));

    // Interactive tweet actions (Like, Retweet, Bookmark)
    Alpine.data('tweetCard', (initialData) => ({
        id: initialData.id,
        isLiked: initialData.isLiked || false,
        likesCount: initialData.likesCount || 0,
        isRetweeted: initialData.isRetweeted || false,
        retweetsCount: initialData.retweetsCount || 0,
        isBookmarked: initialData.isBookmarked || false,
        isLoading: false,

        error: '',
        async toggleAction(url, field, countField) {
            if (this.isLoading) return;
            this.isLoading = true;
            this.error = '';
            const before = this[field];
            try {
                const active = await writeAction(url, {tweet_id: this.id});
                this[field] = active;
                if (countField) this[countField] = Math.max(0, this[countField] + Number(active) - Number(before));
            } catch (err) {
                this.error = 'Could not save this action. Please try again.';
            } finally {
                this.isLoading = false;
            }
        },
        toggleLike(url) { return this.toggleAction(url, 'isLiked', 'likesCount'); },
        toggleRetweet(url) { return this.toggleAction(url, 'isRetweeted', 'retweetsCount'); },
        toggleBookmark(url) { return this.toggleAction(url, 'isBookmarked'); }

    }));

    // Follow / Unfollow button
    Alpine.data('followBtn', (initialFollowing, targetUserId, followUrl, unfollowUrl) => ({
        isFollowing: initialFollowing,
        isHovered: false,

        get buttonText() {
            if (this.isFollowing) {
                return this.isHovered ? 'Unfollow' : 'Following';
            }
            return 'Follow';
        },

        isLoading: false,
        error: '',
        async toggle() {
            if (this.isLoading) return;
            this.isLoading = true;
            this.error = '';
            try {
                this.isFollowing = await writeAction(this.isFollowing ? unfollowUrl : followUrl, {user_id: targetUserId});
            } catch (err) {
                this.error = 'Could not save. Please try again.';
            } finally {
                this.isLoading = false;
            }
        }

    }));
});

/**
 * Global X Toast Notification helper
 */
let xToastTimeout = null;
function showXToast(message) {
    const toast = document.getElementById('xToast');
    const msgEl = document.getElementById('xToastMessage');
    if (!toast) return;
    if (msgEl && message) {
        msgEl.textContent = message;
    }
    toast.classList.add('show');
    if (xToastTimeout) clearTimeout(xToastTimeout);
    xToastTimeout = setTimeout(() => {
        toast.classList.remove('show');
    }, 3000);
}

/**
 * Copy tweet permalink to clipboard with fallback and X Toast feedback
 */
async function copyPostLink(url) {
    const fullUrl = url.startsWith('http') ? url : window.location.origin + url;
    try {
        if (navigator.clipboard && window.isSecureContext) {
            await navigator.clipboard.writeText(fullUrl);
        } else {
            const textArea = document.createElement('textarea');
            textArea.value = fullUrl;
            textArea.style.position = 'fixed';
            textArea.style.left = '-9999px';
            textArea.style.top = '0';
            document.body.appendChild(textArea);
            textArea.focus();
            textArea.select();
            document.execCommand('copy');
            document.body.removeChild(textArea);
        }
        showXToast('Copied to clipboard');
    } catch (err) {
        console.error('Failed to copy link: ', err);
        showXToast('Could not copy the link');
    }
}

/**
 * Setup X-style Delete Post Modal trigger
 */
document.addEventListener('DOMContentLoaded', () => {
    const deleteModalEl = document.getElementById('deletePostModal');
    if (deleteModalEl) {
        deleteModalEl.addEventListener('show.bs.modal', (event) => {
            const button = event.relatedTarget;
            if (button) {
                const tweetId = button.getAttribute('data-tweet-id');
                const idInput = deleteModalEl.querySelector('#deletePostModalId');
                if (idInput && tweetId) {
                    idInput.value = tweetId;
                }
            }
        });
    }
});

