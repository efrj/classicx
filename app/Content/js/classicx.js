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
        triggerFileInput() {
            if (this.$refs.fileInput) {
                this.$refs.fileInput.click();
            }
        },
        async handleFileUpload(event) {
            const file = event.target.files && event.target.files[0];
            if (!file) return;

            if (!file.type.startsWith('image/')) {
                this.uploadError = 'Please select a valid image (PNG, JPG, GIF, WEBP).';
                showXToast(this.uploadError);
                return;
            }
            if (file.size > 10 * 1024 * 1024) {
                this.uploadError = 'Image must be smaller than 10MB.';
                showXToast(this.uploadError);
                return;
            }

            this.isUploading = true;
            this.uploadError = '';

            try {
                const formData = new FormData();
                formData.append('image_file', file);
                const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content || '';
                formData.append('csrf_token', csrfToken);

                const response = await fetch('/tweets/upload', {
                    method: 'POST',
                    body: formData
                });

                const data = await response.json();
                if (!response.ok || !data.success) {
                    throw new Error(data.error || 'Failed to upload image to RustFS');
                }

                this.imageUrl = data.url;
                showXToast('Image uploaded to RustFS');
            } catch (err) {
                console.error('RustFS upload failed:', err);
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

