<%
Dim modalUser : Set modalUser = Auth.CurrentUser
%>

<div class="modal fade" id="composeModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content x-modal-dark p-3" x-data="composeBox()">
            <div class="modal-header border-0 pb-0">
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body pt-2 pb-0">
                <div class="d-flex gap-3">
                    <img src="<%= H(modalUser.AvatarUrl) %>" alt="<%= H(modalUser.Name) %>" class="x-compose-avatar">
                    <div class="w-100">
                        <form action="<%= Routes.UrlTo("Tweets", "CreatePost", Empty) %>" method="POST">
                            <input type="hidden" name="csrf_token" value="<%= H(CsrfToken()) %>">
<textarea aria-label="Post content" maxlength="280" required name="content" 
                                      class="x-compose-textarea" 
                                      placeholder="What is happening?!" 
                                      x-model="content" 
                                      @input="autoExpand($event)"
                                      maxlength="280"
                                      rows="3"></textarea>

                            <div x-show="showMediaInput" x-transition class="mb-3">
                                <div class="input-group input-group-sm">
                                    <span class="input-group-text bg-dark border-secondary text-secondary"><i class="bi bi-link-45deg"></i></span>
                                    <input type="url" name="image_url" aria-label="Image URL" maxlength="255" class="form-control bg-dark text-white border-secondary" placeholder="Paste image URL (e.g. https://...)" x-model="imageUrl">
                                </div>
                                <template x-if="imageUrl">
                                    <div class="mt-2 position-relative rounded-3 overflow-hidden border border-secondary" style="max-height: 180px;">
                                        <img :src="imageUrl" class="w-100 object-fit-cover" style="max-height: 180px;" alt="Preview">
                                        <button type="button" @click="imageUrl = ''" class="btn btn-sm btn-dark position-absolute top-0 end-0 m-2 rounded-circle">
                                            <i class="bi bi-x"></i>
                                        </button>
                                    </div>
                                </template>
                            </div>

                            <div class="x-compose-actions">
                                <div class="x-compose-icons">
                                    <button type="button" class="x-compose-icon-btn" @click="toggleMedia()">
                                        <i class="bi bi-image"></i>
                                    </button>
                                    <button type="button" class="x-compose-icon-btn" @click="content += ' 𝕏'">
                                        <i class="bi bi-twitter-x"></i>
                                    </button>
                                </div>

                                <div class="d-flex align-items-center gap-3">
                                    <div class="d-flex align-items-center gap-2" x-show="content.length > 0">
                                        <svg width="24" height="24" viewBox="0 0 36 36">
                                            <path fill="none" stroke="#2f3336" stroke-width="3" d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"></path>
                                            <path fill="none" :stroke="progressColor" stroke-width="3" :stroke-dasharray="progressPercent + ', 100'" d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"></path>
                                        </svg>
                                        <span class="smaller" :style="'color: ' + progressColor" x-show="charsRemaining <= 20" x-text="charsRemaining"></span>
                                    </div>
                                    <button type="submit" class="x-btn-tweet-submit" :disabled="!isValid">
                                        Post
                                    </button>
                                </div>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
