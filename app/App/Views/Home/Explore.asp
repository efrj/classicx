<!-- Explore Header -->
<header class="x-header-sticky px-3 py-2">
    <form action="<%= Routes.UrlTo("Home", "Explore", Empty) %>" method="GET">
<input type="hidden" name="_A" value="Explore">
        <div class="x-search-box mb-0">
            <i class="bi bi-search"></i>
            <input type="text" name="q" aria-label="Search posts" class="x-search-input" placeholder="Search ClassicX" value="<%= H(Model.Query) %>" autocomplete="off">
        </div>
    </form>
</header>

<% If Model.Query <> "" Then %>
    <div class="p-3 border-bottom border-secondary">
        <h6 class="text-secondary small mb-1">Search results for</h6>
        <h4 class="fw-bold text-white mb-0">"<%= H(Model.Query) %>"</h4>
    </div>
<% Else %>
    <!-- Trending banner -->
    <div class="p-4 border-bottom border-secondary" style="background: linear-gradient(180deg, rgba(29,155,240,0.15) 0%, rgba(0,0,0,0) 100%);">
        <div class="badge bg-primary mb-2">Technology · Trending</div>
        <h3 class="fw-bold text-white">ClassicX: Rebuilding the Web with ASP & MariaDB</h3>
        <p class="text-secondary mb-0">Discover trending topics, discussions, and posts across the community.</p>
    </div>
<% End If %>

<!-- Tweets List -->
<div class="x-tweets-stream">
    <%
        Dim expIt : Set expIt = Model.Tweets.GetIterator
        If Not expIt.HasNext Then
    %>
        <div class="text-center py-5 px-4">
            <i class="bi bi-search text-secondary" style="font-size: 2.5rem;"></i>
            <h5 class="fw-bold mt-3 text-white">No results found</h5>
            <p class="text-secondary small">Try searching for people, topics, or keywords like "#ClassicASP" or "MariaDB".</p>
        </div>
    <%
        Else
            Do While expIt.HasNext
                Dim tweetItem : Set tweetItem = expIt.GetNext
    %>
                <!--#include file="../Shared/_TweetCard.asp"-->
    <%
            Loop
        End If
    %>
</div>
