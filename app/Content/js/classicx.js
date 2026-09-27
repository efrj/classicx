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
    // Tweet composer component
    Alpine.data('composeBox', () => ({
        content: '',
        imageUrl: '',
        showMediaInput: false,
        maxChars: 280,

        get charCount() {
            return this.content.length;
        },
        get charsRemaining() {
            return this.maxChars - this.content.length;
        },
        get isValid() {
            return this.content.trim().length > 0 && this.content.length <= this.maxChars;
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
