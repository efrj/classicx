<% If Not MVC.IsPartial Then %>
<!DOCTYPE html>
<html lang="en" data-bs-theme="dark">
<head>
    <meta charset="utf-8">
    <meta name="csrf-token" content="<%= H(CsrfToken()) %>">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>ClassicX / 𝕏 Clone (ASP VBScript + Sane MVC)</title>
    
    <!-- Favicon -->
    <link rel="icon" href="data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24'><path fill='%23ffffff' d='M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z'/></svg>">

    <!-- Google Fonts - Inter -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">

    <!-- Bootstrap 5.3 CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">

    <!-- Bootstrap Icons -->
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">

    <!-- ClassicX Dark Theme CSS -->
    <link rel="stylesheet" href="<%= Routes.StylesheetsUrl %>classicx.css">

    <!-- Alpine.js -->
    <script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.14.8/dist/cdn.min.js"></script>

    <!-- Bootstrap 5.3 JS -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>

    <!-- ClassicX JS -->
    <script src="<%= Routes.ContentUrl %>js/classicx.js"></script>
</head>

<body id="MVC-<%= H(MVC.ControllerName) & "-" & H(MVC.ActionName) %>">
<% If MVC.ControllerName = "Auth" Then %>
    <!-- Focused Single-Column Layout for Auth Pages -->
    <div class="container min-vh-100 d-flex flex-column justify-content-center align-items-center py-4">
        <%
            Flash.ShowErrorsIfPresent
            Flash.ShowSuccessIfPresent
        %>
<% Else %>
    <!-- Standard 3-Column Twitter Layout -->
    <div class="container-fluid container-xl">
        <div class="row min-vh-100 gx-0 gx-md-3">
            <!-- Left Sidebar Navigation -->
            <!--#include file="_SidebarLeft.asp"-->

            <!-- Center Feed Column -->
            <main class="col col-md-9 col-lg-8 col-xl-6 x-center-col">
                <%
                    Flash.ShowErrorsIfPresent
                    Flash.ShowSuccessIfPresent
                %>
<% End If %>
<% End If %>
