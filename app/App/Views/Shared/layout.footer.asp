
<% If Not MVC.IsPartial Then %>
<% If MVC.ControllerName = "Auth" Then %>
    </div><!-- /.container -->
<% Else %>
            </main><!-- /.x-center-col -->

            <!-- Right Sidebar Widgets -->
            <!--#include file="_SidebarRight.asp"-->
        </div><!-- /.row -->
    </div><!-- /.container-xl -->

    <!-- Modals -->
    <!--#include file="_ComposeModal.asp"-->
    <!--#include file="_DeletePostModal.asp"-->
<% End If %>

<!-- X Bottom Notification Toast / Pill -->
<div id="xToastContainer" class="x-toast-container" aria-live="polite">
    <div id="xToast" class="x-toast-pill" role="status">
        <span id="xToastMessage">Copied to clipboard</span>
    </div>
</div>

</body>
</html>
<% End If %>

<% DAL.Close %>
