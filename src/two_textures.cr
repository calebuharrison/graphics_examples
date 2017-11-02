require "crystglfw"
require "crystgl"
require "crystimage"

module TwoTextures
  include CrystGLFW
  include CrystGL

  CrystGLFW.run do

    # Configure CrystImage to flip images vertically upon loading them.
    CrystImage.on_load { |config| config.flip_vertically = true }

    window_size = {width: 800, height: 600}

    hints = { 
      Window::HintLabel::ContextVersionMajor => 3,
      Window::HintLabel::ContextVersionMinor => 3,
      Window::HintLabel::OpenGLForwardCompat => true,
      Window::HintLabel::OpenGLProfile       => OpenGLProfile::Core,
      Window::HintLabel::ClientAPI           => ClientAPI::OpenGL
    }

    vertex_shader_source = <<-SHADER
      #version 330 core
      layout (location = 0) in vec3 aPos;
      layout (location = 1) in vec3 aColor;
      layout (location = 2) in vec2 aTexCoord;
      
      out vec3 ourColor;
      out vec2 TexCoord;

      void main()
      {
        gl_Position = vec4(aPos, 1.0);
        ourColor = aColor;
        TexCoord = vec2(aTexCoord.x, aTexCoord.y);
      }
    SHADER

    fragment_shader_source = <<-SHADER
      #version 330 core
      in vec3 ourColor;
      in vec2 TexCoord;

      out vec4 FragColor;

      uniform sampler2D texture1;
      uniform sampler2D texture2;

      void main()
      {
        FragColor = mix(texture(texture1, TexCoord), texture(texture2, TexCoord), texture(texture2, TexCoord).a * 0.2);
      }
    SHADER

    window = Window.new(width: window_size[:width], height: window_size[:height], title: "Two Textures!", hints: hints)
    window.make_context_current

    window.on_framebuffer_resize do |event|
      LibGL.viewport(0, 0, event.size[:width], event.size[:height])
      window_size = event.size
    end

    window.on_key do |event|
      if event.action.press? && event.key.escape?
        event.window.should_close
      end
    end

    vertex_shader = VertexShader.create(vertex_shader_source)
    fragment_shader = FragmentShader.create(fragment_shader_source)
    shaders = {vertex_shader, fragment_shader}
    program = Program.create(shaders)

    vertices = {
        # ------ positions -------    -------- colors ----------    texture coordinates
        0.5f32,   0.5f32,   0.0f32,   1.0f32,   0.0f32,   0.0f32,   1.0f32,   1.0f32, # top right
        0.5f32,  -0.5f32,   0.0f32,   0.0f32,   1.0f32,   0.0f32,   1.0f32,   0.0f32, # bottom right
       -0.5f32,  -0.5f32,   0.0f32,   0.0f32,   0.0f32,   1.0f32,   0.0f32,   0.0f32, # bottom left
       -0.5f32,   0.5f32,   0.0f32,   1.0f32,   1.0f32,   0.0f32,   0.0f32,   1.0f32  # top left
    }

    # Indices used for indexed draw calls. Each is used as an index into the four vertices.
    indices = {
      0, 1, 3,  # first triangle
      1, 2, 3   # second triangle
    }

    vertex_buffer = Buffer.new
    element_buffer = Buffer.new
    vertex_array  = VertexArray.new

    vertex_array.bind do
      vertex_buffer.bind(Buffer::Target::Array) do |buffer, target|
        target.buffer_data(vertices, Buffer::UsageHint::StaticDraw)
        vertex_array.define_attributes do |va|
          va.attribute(3, DataType::Float, false)
          va.attribute(3, DataType::Float, false)
          va.attribute(2, DataType::Float, false)
        end
      end

      # bind the element buffer to GL_ELEMENT_ARRAY_BUFFER
      element_buffer.bind(Buffer::Target::ElementArray)

      # Send index data to the GPU.
      Buffer::Target::ElementArray.buffer_data(indices, Buffer::UsageHint::StaticDraw)
    end
    
    # unbind the element buffer.
    element_buffer.unbind

    texture_params = {
      Texture::ParameterName::TextureWrapS      => Texture::ParameterValue::Repeat,
      Texture::ParameterName::TextureWrapT      => Texture::ParameterValue::Repeat,
      Texture::ParameterName::TextureMinFilter  => Texture::ParameterValue::Linear,
      Texture::ParameterName::TextureMagFilter  => Texture::ParameterValue::Linear
    }

    container = Texture.new
    container.bind(Texture::Target::Texture2D) do |tex, target|
      target.set_parameters(texture_params)
      CrystImage.open("src/images/container.jpg") do |image|
        target.image_2d(0, BaseInternalFormat::RGB, image.width, image.height, Format::RGB, DataType::UnsignedByte, image.data)
        target.generate_mipmap
      end
    end

    face = Texture.new
    face.bind(Texture::Target::Texture2D) do |tex, target|
      target.set_parameters(texture_params)
      CrystImage.open("src/images/awesomeface.png") do |image|
        target.image_2d(0, BaseInternalFormat::RGBA, image.width, image.height, Format::RGBA, DataType::UnsignedByte, image.data)
        target.generate_mipmap
      end
    end

    program.use do |p|
      p.set_uniform("texture1", 0)
      p.set_uniform("texture2", 1)
    end

    Texture::Unit.activate(0)
    container.bind(Texture::Target::Texture2D)
    Texture::Unit.activate(1)
    face.bind(Texture::Target::Texture2D)

    until window.should_close?
      LibGL.clear_color(0.2, 0.3, 0.3, 1.0)
      LibGL.clear(Buffer::Bit::Color)

      program.use do
        vertex_array.bind do
          LibGL.draw_elements(LibGL::TRIANGLES, 6, DataType::UnsignedInt, Pointer(Void).new(0))
        end
      end

      window.swap_buffers
      CrystGLFW.wait_events(0.015)
    end

    {vertex_array, vertex_buffer, element_buffer}.each { |v| v.delete }

    window.destroy
  end
end