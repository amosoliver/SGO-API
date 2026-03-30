# frozen_string_literal: true

class SwaggerUiHtml
  extend SwaggerBasicAuth

  def self.call(env)
    unauthorized = authenticate!(env)
    return unauthorized if unauthorized

    body = <<~HTML
      <!DOCTYPE html>
      <html lang="pt-BR">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Ambiental API Swagger</title>
        <link rel="stylesheet" href="https://unpkg.com/swagger-ui-dist@5/swagger-ui.css">
        <style>
          html { box-sizing: border-box; overflow-y: scroll; }
          *, *::before, *::after { box-sizing: inherit; }
          body { margin: 0; background: #f5f5f5; }
          .topbar { display: none; }
          .toolbar {
            position: sticky;
            top: 0;
            z-index: 10;
            display: flex;
            justify-content: flex-end;
            gap: 12px;
            padding: 12px 16px;
            background: #111827;
            box-shadow: 0 1px 2px rgba(0, 0, 0, 0.2);
          }
          .toolbar button {
            appearance: none;
            border: 0;
            border-radius: 8px;
            padding: 10px 14px;
            font: 600 14px/1.2 sans-serif;
            color: #fff;
            background: #2563eb;
            cursor: pointer;
          }
          .toolbar button:hover {
            background: #1d4ed8;
          }
        </style>
      </head>
      <body>
        <div class="toolbar">
          <button type="button" onclick="reloadSwaggerDocs()">Atualizar documentação</button>
        </div>
        <div id="swagger-ui"></div>
        <script src="https://unpkg.com/swagger-ui-dist@5/swagger-ui-bundle.js"></script>
        <script src="https://unpkg.com/swagger-ui-dist@5/swagger-ui-standalone-preset.js"></script>
        <script>
          const swaggerUrl = "/swagger/openapi.json";

          function buildSwaggerUrl() {
            return `${swaggerUrl}?t=${Date.now()}`;
          }

          function mountSwagger() {
            window.ui = SwaggerUIBundle({
              url: buildSwaggerUrl(),
              dom_id: "#swagger-ui",
              deepLinking: true,
              presets: [
                SwaggerUIBundle.presets.apis,
                SwaggerUIStandalonePreset
              ],
              layout: "StandaloneLayout",
              persistAuthorization: true,
              displayRequestDuration: true,
              docExpansion: "list",
              defaultModelsExpandDepth: 2,
              defaultModelExpandDepth: 2
            });
          }

          function reloadSwaggerDocs() {
            const container = document.getElementById("swagger-ui");
            container.innerHTML = "";
            mountSwagger();
          }

          window.onload = function() {
            mountSwagger();
          };
        </script>
      </body>
      </html>
    HTML

    [200, { "Content-Type" => "text/html" }, [body]]
  end
end
