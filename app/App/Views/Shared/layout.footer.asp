
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
<% End If %>

</body>
</html>
<% End If %>

<% DAL.Close %>
