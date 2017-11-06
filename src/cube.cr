require "crystglfw"
require "crystgl"
require "crystimage"
require "redemption"

module Transformation
  include CrystGLFW
  include CrystGL
  include Redemption

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
      layout (location = 1) in vec2 aTexCoord;
      
      out vec2 TexCoord;

      uniform mat4 transform;

      void main()
      {
        gl_Position = transform * vec4(aPos, 1.0);
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

    window = Window.new(width: window_size[:width], height: window_size[:height], title: "Transformation!", hints: hints)
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
      -0.5f32, -0.5f32, -0.5f32,  0.0f32, 0.0f32,
       0.5f32, -0.5f32, -0.5f32,  1.0f32, 0.0f32,
       0.5f32,  0.5f32, -0.5f32,  1.0f32, 1.0f32,
       0.5f32,  0.5f32, -0.5f32,  1.0f32, 1.0f32,
      -0.5f32,  0.5f32, -0.5f32,  0.0f32, 1.0f32,
      -0.5f32, -0.5f32, -0.5f32,  0.0f32, 0.0f32,

      -0.5f32, -0.5f32,  0.5f32,  0.0f32, 0.0f32,
       0.5f32, -0.5f32,  0.5f32,  1.0f32, 0.0f32,
       0.5f32,  0.5f32,  0.5f32,  1.0f32, 1.0f32,
       0.5f32,  0.5f32,  0.5f32,  1.0f32, 1.0f32,
      -0.5f32,  0.5f32,  0.5f32,  0.0f32, 1.0f32,
      -0.5f32, -0.5f32,  0.5f32,  0.0f32, 0.0f32,

      -0.5f32,  0.5f32,  0.5f32,  1.0f32, 0.0f32,
      -0.5f32,  0.5f32, -0.5f32,  1.0f32, 1.0f32,
      -0.5f32, -0.5f32, -0.5f32,  0.0f32, 1.0f32,
      -0.5f32, -0.5f32, -0.5f32,  0.0f32, 1.0f32,
      -0.5f32, -0.5f32,  0.5f32,  0.0f32, 0.0f32,
      -0.5f32,  0.5f32,  0.5f32,  1.0f32, 0.0f32,

       0.5f32,  0.5f32,  0.5f32,  1.0f32, 0.0f32,
       0.5f32,  0.5f32, -0.5f32,  1.0f32, 1.0f32,
       0.5f32, -0.5f32, -0.5f32,  0.0f32, 1.0f32,
       0.5f32, -0.5f32, -0.5f32,  0.0f32, 1.0f32,
       0.5f32, -0.5f32,  0.5f32,  0.0f32, 0.0f32,
       0.5f32,  0.5f32,  0.5f32,  1.0f32, 0.0f32,

      -0.5f32, -0.5f32, -0.5f32,  0.0f32, 1.0f32,
       0.5f32, -0.5f32, -0.5f32,  1.0f32, 1.0f32,
       0.5f32, -0.5f32,  0.5f32,  1.0f32, 0.0f32,
       0.5f32, -0.5f32,  0.5f32,  1.0f32, 0.0f32,
      -0.5f32, -0.5f32,  0.5f32,  0.0f32, 0.0f32,
      -0.5f32, -0.5f32, -0.5f32,  0.0f32, 1.0f32,

      -0.5f32,  0.5f32, -0.5f32,  0.0f32, 1.0f32,
       0.5f32,  0.5f32, -0.5f32,  1.0f32, 1.0f32,
       0.5f32,  0.5f32,  0.5f32,  1.0f32, 0.0f32,
       0.5f32,  0.5f32,  0.5f32,  1.0f32, 0.0f32,
      -0.5f32,  0.5f32,  0.5f32,  0.0f32, 0.0f32,
      -0.5f32,  0.5f32, -0.5f32,  0.0f32, 1.0f32
    }

    vertex_buffer = Buffer.new
    vertex_array  = VertexArray.new

    vertex_array.bind do
      vertex_buffer.bind(Buffer::Target::Array) do |buffer, target|
        target.buffer_data(vertices, Buffer::UsageHint::StaticDraw)
        vertex_array.define_attributes do |va|
          va.attribute(3, DataType::Float, false)
          va.attribute(2, DataType::Float, false)
        end
      end
    end
    
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

    view = Matrix4x4f32.translation(0, 0, -3)

    LibGL.enable(LibGL::DEPTH_TEST)

    until window.should_close?
      LibGL.clear_color(0.2, 0.3, 0.3, 1.0)
      LibGL.clear(Buffer::Bit::Color | Buffer::Bit::Depth)

      model = Matrix4x4f32.rotation(CrystGLFW.time, 0.5, 1.0, 0)
      projection = Matrix4x4f32.perspective(45 * (Math::PI / 180), window_size[:width] / window_size[:height], 0.1, 100)
      transformation = projection * view * model

      program.use do |p|
        p.set_uniform("transform", 1, true, transformation.flat) 
        vertex_array.bind do
          LibGL.draw_arrays(LibGL::TRIANGLES, 0, 36)
        end
      end

      window.swap_buffers
      CrystGLFW.wait_events(0.015)
    end

    {vertex_array, vertex_buffer}.each { |v| v.delete }

    window.destroy
  end
end