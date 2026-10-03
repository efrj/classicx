<!-- Top sticky header -->
<header class="x-header-sticky px-3 py-2 d-flex align-items-center gap-3">
    <a href="<%= Routes.UrlTo("Home", "Index", Empty) %>" class="btn btn-icon text-white rounded-circle p-1" title="Back to Timeline">
        <i class="bi bi-arrow-left fs-5"></i>
    </a>
    <div>
        <h1 class="h5 fw-bold mb-0 text-white"><%= H(Model.ProfileUser.Name) %></h1>
        <div class="text-secondary smaller"><%= Model.ProfileUser.TweetsCount %> posts</div>
    </div>
</header>

<!-- Profile Banner -->
<div class="x-profile-banner" <% If Model.ProfileUser.BannerUrl <> "" Then %>style="background-image: url('<%= H(Model.ProfileUser.BannerUrl) %>');"<% End If %>>
    <div class="x-profile-avatar-wrap">
        <img src="<%= H(Model.ProfileUser.AvatarUrl) %>" alt="<%= H(Model.ProfileUser.Name) %>" class="x-profile-avatar">
    </div>
</div>

<!-- Profile Action Bar (Edit profile or Follow button) -->
<div class="x-profile-actions">
    <% If Model.ProfileUser.Id = Auth.CurrentUserId Then %>
        <button type="button" class="btn btn-outline-light rounded-pill fw-bold btn-sm px-3" data-bs-toggle="modal" data-bs-target="#editProfileModal">
            Edit profile
        </button>
    <% Else %>
        <div x-data="followBtn(<%= Choice(Model.ProfileUser.IsFollowedByCurrent, "true", "false") %>, <%= Model.ProfileUser.Id %>, '<%= Routes.UrlTo("Users", "FollowPost", Empty) %>', '<%= Routes.UrlTo("Users", "UnfollowPost", Empty) %>')">
            <button type="button" 
                    :class="isFollowing ? 'x-btn-following' : 'x-btn-follow'"
                    @mouseenter="isHovered = true" 
                    @mouseleave="isHovered = false"
                    @click="toggle()" :disabled="isLoading" 
                    x-text="buttonText">
                Follow
            </button>
            <p class="text-danger small mb-0" role="status" x-text="error"></p>
        </div>
    <% End If %>
</div>

<!-- Profile Details -->
<section class="x-profile-details">
    <div class="x-profile-name text-white">
        <%= H(Model.ProfileUser.Name) %>
        <% If Model.ProfileUser.IsVerified Then %>
            <i class="bi bi-patch-check-fill x-badge-verified ms-1"></i>
        <% End If %>
    </div>
    <div class="text-secondary small mb-2">@<%= H(Model.ProfileUser.Handle) %></div>

    <% If Len(Model.ProfileUser.Bio) > 0 Then %>
        <div class="x-profile-bio text-white"><%= H(Model.ProfileUser.Bio) %></div>
    <% End If %>

    <div class="x-profile-meta">
        <% If Len(Model.ProfileUser.Location) > 0 Then %>
            <div><i class="bi bi-geo-alt me-1"></i><%= H(Model.ProfileUser.Location) %></div>
        <% End If %>
        <% If Len(Model.ProfileUser.Website) > 0 Then %>
            <div>
                <i class="bi bi-link-45deg me-1"></i>
                <a href="<%= H(Model.ProfileUser.Website) %>" target="_blank" rel="noopener noreferrer" class="text-primary text-decoration-none hover-underline"><%= H(Model.ProfileUser.Website) %></a>
            </div>
        <% End If %>
        <div>
            <i class="bi bi-calendar3 me-1"></i>
            <%
                Dim joinText : joinText = "Joined ClassicX"
                If IsDate(Model.ProfileUser.CreatedAt) Then
                    joinText = "Joined " & MonthName(Month(Model.ProfileUser.CreatedAt)) & " " & Year(Model.ProfileUser.CreatedAt)
                End If
            %>
            <%= H(joinText) %>
        </div>
    </div>

    <div class="x-profile-stats">
        <a href="<%= Routes.UrlTo("Users", "Following", Array("handle", Model.ProfileUser.Handle)) %>">
            <span><%= Model.ProfileUser.FollowingCount %></span> Following
        </a>
        <a href="<%= Routes.UrlTo("Users", "Followers", Array("handle", Model.ProfileUser.Handle)) %>">
            <span><%= Model.ProfileUser.FollowersCount %></span> Followers
        </a>
    </div>
</section>

<!-- Tabs (Posts, Replies, Likes) -->
<nav class="x-header-tabs" aria-label="Profile posts">
<%
Dim pTab
For Each pTab In Array("posts", "replies", "likes")
%>
    <a class="x-header-tab <%= Choice(Model.ActiveTab = pTab, "active", "") %>" href="<%= H(Routes.UrlTo("Users", "Profile", Array("handle", Model.ProfileUser.Handle, "tab", pTab))) %>">
        <%= UCase(Left(pTab, 1)) & Mid(pTab, 2) %>
    </a>
<% Next %>
</nav>

<!-- Posts Feed -->
<!--#include file="../Shared/_Feed.asp"-->

<!-- Edit Profile Modal (Only for current user) -->
<% If Model.ProfileUser.Id = Auth.CurrentUserId Then %>
<div class="modal fade" id="editProfileModal" tabindex="-1" aria-labelledby="editProfileModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered modal-dialog-scrollable">
        <div class="modal-content bg-black border border-secondary text-white rounded-4 shadow-lg">
            <form method="POST" action="<%= Routes.UrlTo("Users", "UpdateProfilePost", Empty) %>" x-data="profileEditor()" @submit="prepareSubmit($event)">
                <input type="hidden" name="csrf_token" value="<%= H(CsrfToken()) %>">
                <input type="hidden" name="banner_url" value="<%= H(Model.ProfileUser.BannerUrl) %>">
                <input type="hidden" name="avatar_url" value="<%= H(Model.ProfileUser.AvatarUrl) %>">
                <div class="modal-header border-secondary p-3">
                    <button type="button" class="btn-close btn-close-white me-2" data-bs-dismiss="modal" aria-label="Close"></button>
                    <h5 class="modal-title fw-bold fs-6 flex-grow-1" id="editProfileModalLabel">Edit profile</h5>
                    <button type="submit" class="btn btn-light rounded-pill btn-sm fw-bold px-3" :disabled="uploading !== ''">Save</button>
                </div>
                <div class="modal-body p-0">
                    <div class="x-edit-hero">
                        <div class="x-edit-banner" <% If Model.ProfileUser.BannerUrl <> "" Then %>style="background-image: url('<%= H(Model.ProfileUser.BannerUrl) %>');"<% End If %> :style="bannerStyle">
                            <button type="button" class="x-edit-media-btn" @click="pick('banner')" :disabled="uploading !== ''" aria-label="Upload banner image">
                                <i class="bi bi-camera" x-show="uploading !== 'banner'"></i>
                                <span x-show="uploading === 'banner'" x-cloak class="spinner-border spinner-border-sm" role="status" aria-label="Uploading banner"></span>
                            </button>
                            <input type="file" x-ref="bannerFile" class="x-file-input" accept="image/png,image/jpeg,image/webp,image/gif" @change="upload('banner', $event)">
                        </div>
                        <div class="x-edit-avatar">
                            <img src="<%= H(Model.ProfileUser.AvatarUrl) %>" :src="avatarUrl" alt="<%= H(Model.ProfileUser.Name) %>">
                            <button type="button" class="x-edit-media-btn" @click="pick('avatar')" :disabled="uploading !== ''" aria-label="Upload avatar image">
                                <i class="bi bi-camera" x-show="uploading !== 'avatar'"></i>
                                <span x-show="uploading === 'avatar'" x-cloak class="spinner-border spinner-border-sm" role="status" aria-label="Uploading avatar"></span>
                            </button>
                            <input type="file" x-ref="avatarFile" class="x-file-input" accept="image/png,image/jpeg,image/webp,image/gif" @change="upload('avatar', $event)">
                        </div>
                    </div>
                    <div class="px-3 pb-3">
                    <div x-show="uploadError" x-cloak class="x-upload-status x-upload-status-error mb-3" role="alert">
                        <span class="x-upload-status-text" x-text="uploadError"></span>
                        <button type="button" class="x-upload-dismiss" @click.prevent="dismissUploadError()" aria-label="Dismiss upload error">
                            <i class="bi bi-x-lg" aria-hidden="true"></i>
                        </button>
                    </div>
                    <div class="form-floating mb-3">
                        <input type="text" name="name" id="profileNameInput" class="form-control bg-black text-white border-secondary" value="<%= H(Model.ProfileUser.Name) %>" required maxlength="50" placeholder="Name">
                        <label for="profileNameInput" class="text-secondary">Name</label>
                    </div>
                    <div class="mb-3">
                        <label for="profileBioInput" class="form-label text-secondary small fw-bold mb-1">Bio</label>
                        <textarea name="bio" id="profileBioInput" class="form-control bg-black text-white border-secondary x-profile-bio-input" maxlength="160" placeholder="Bio" @input="bioCount = $event.target.value.length"><%= H(Model.ProfileUser.Bio) %></textarea>
                        <div class="text-secondary small text-end mt-1"><span x-text="bioCount"><%= Len(Model.ProfileUser.Bio) %></span> / 160</div>
                    </div>
                    <div class="form-floating mb-3">
                        <input type="text" name="location" id="profileLocInput" class="form-control bg-black text-white border-secondary" value="<%= H(Model.ProfileUser.Location) %>" maxlength="30" placeholder="Location">
                        <label for="profileLocInput" class="text-secondary">Location</label>
                    </div>
                    <div class="form-floating mb-3">
                        <input type="text" name="website" id="profileWebInput" class="form-control bg-black text-white border-secondary" value="<%= H(Model.ProfileUser.Website) %>" maxlength="100" placeholder="Website">
                        <label for="profileWebInput" class="text-secondary">Website</label>
                    </div>
                    </div>
                </div>
            </form>
        </div>
    </div>
</div>
<% End If %>
