<%
Dim composeUser : Set composeUser = Auth.CurrentUser
%>

<div class="x-compose-box" x-data="composeBox()">
    <img src="<%= H(composeUser.AvatarUrl) %>" alt="<%= H(composeUser.Name) %>" class="x-compose-avatar">
    <div class="x-compose-content">
        <form action="<%= Routes.UrlTo("Tweets", "CreatePost", Empty) %>" method="POST" @submit="prepareSubmit($event)">
            <input type="hidden" name="csrf_token" value="<%= H(CsrfToken()) %>">
<textarea aria-label="Post content" maxlength="280" required name="content" 
                      class="x-compose-textarea" 
                      placeholder="What is happening?!" 
                      x-model="content" 
                      @input="autoExpand($event)"
                      maxlength="280"
                      rows="2"></textarea>

            <!--#include file="_ComposeMedia.asp"-->

            <div class="x-compose-actions">
                <div class="x-compose-icons">
                    <button type="button" class="x-compose-icon-btn" @click="triggerFileInput()" :disabled="isUploading" title="Upload image to RustFS">
                        <i class="bi bi-image"></i>
                    </button>
                    <button type="button" class="x-compose-icon-btn" @click="toggleMedia()" title="Paste image URL">
                        <i class="bi bi-link-45deg"></i>
                    </button>
                    <button type="button" class="x-compose-icon-btn" @click="content += ' 🚀'" title="Add emoji">
                        <i class="bi bi-emoji-smile"></i>
                    </button>
                    <button type="button" class="x-compose-icon-btn" @click="content += ' #ClassicASP'" title="Add hashtag">
                        <i class="bi bi-hash"></i>
                    </button>
                </div>

                <div class="d-flex align-items-center gap-3">
                    <!-- Circular character counter meter -->
                    <div x-show="content.length > 0" x-cloak>
                    <div class="d-flex align-items-center gap-2">
                        <svg width="24" height="24" viewBox="0 0 36 36">
                            <path fill="none" stroke="#2f3336" stroke-width="3" d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"></path>
                            <path fill="none" :stroke="progressColor" stroke-width="3" :stroke-dasharray="progressPercent + ', 100'" d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"></path>
                        </svg>
                        <span class="smaller" :style="'color: ' + progressColor" x-show="charsRemaining <= 20" x-cloak x-text="charsRemaining"></span>
                    </div>
                    </div>

                    <button type="submit" class="x-btn-tweet-submit" :disabled="!isValid || isUploading">
                        Post
                    </button>
                </div>
            </div>
        </form>
    </div>
</div>
