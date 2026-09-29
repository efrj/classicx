<!-- X-style Delete Post Confirmation Modal -->
<div class="modal fade" id="deletePostModal" tabindex="-1" aria-labelledby="deletePostModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered x-modal-delete-dialog">
        <div class="modal-content x-modal-delete p-4">
            <div class="modal-body p-0 text-start">
                <h2 class="x-modal-delete-title" id="deletePostModalLabel">Delete post?</h2>
                <p class="x-modal-delete-desc">
                    This can’t be undone and it will be removed from your profile, the timeline of any accounts that follow you, and from search results.
                </p>
                <form id="deletePostForm" action="<%= Routes.UrlTo("Tweets", "DeletePost", Empty) %>" method="POST" class="d-flex flex-column gap-3 mb-0">
                    <input type="hidden" name="csrf_token" value="<%= H(CsrfToken()) %>">
                    <input type="hidden" name="id" id="deletePostModalId" value="">
                    <button type="submit" class="x-btn-delete-confirm">Delete</button>
                    <button type="button" class="x-btn-delete-cancel" data-bs-dismiss="modal">Cancel</button>
                </form>
            </div>
        </div>
    </div>
</div>
