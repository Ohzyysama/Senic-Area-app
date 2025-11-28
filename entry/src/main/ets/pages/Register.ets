import router from '@ohos.router';
import http from '@ohos.net.http';
import { common } from '@kit.AbilityKit';

// 类型定义
interface RegisterRequestData {
  username: string;
  password: string;
  nickName: string;
}

interface RegisterResponseData {
  userId: number;
  token: string;
}

interface RegisterResponse {
  success: boolean;  // 改为 success
  message: string;
  data: RegisterResponseData;
}

@Entry
@Component
struct Register {
  @State username: string = '';
  @State password: string = '';
  @State confirmPassword: string = '';
  @State nickName: string = '';
  @State isLoading: boolean = false;
  @State errorMessage: string = '';
  @State successMessage: string = '';
  @State serverIP:string = ''

  private async loadServerIP() {
    this.serverIP = await this.getServerIP();
    console.log('加载的服务器IP:', this.serverIP);
  }

  private async getServerIP(): Promise<string> {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const resourceMgr = context.resourceManager;
      const ipValue = await resourceMgr.getString($r('app.string.ip').id);
      return ipValue;
    } catch (error) {
      console.error('获取服务器IP失败:', error);
      return 'localhost:8080';
    }
  }

  private httpRequest: http.HttpRequest = http.createHttp();

  build() {
    Column() {
      // 标题
      Text('用户注册')
        .fontSize(30)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 60, bottom: 40 });

      // 错误提示
      if (this.errorMessage) {
        Text(this.errorMessage)
          .fontSize(14)
          .fontColor('#FF6B35')
          .margin({ bottom: 20 })
          .width('80%')
          .textAlign(TextAlign.Center)
      }

      // 成功提示
      if (this.successMessage) {
        Text(this.successMessage)
          .fontSize(14)
          .fontColor('#52C41A')
          .margin({ bottom: 20 })
          .width('80%')
          .textAlign(TextAlign.Center)
      }

      // 用户名输入框
      TextInput({ placeholder: '请输入用户名', text: this.username })
        .width('80%')
        .height(50)
        .padding(10)
        .margin({ bottom: 20 })
        .borderRadius(8)
        .border({ width: 1, color: '#E5E5E5' })
        .onChange((value: string) => {
          this.username = value;
          this.clearMessages();
        });

      // 密码输入框
      TextInput({ placeholder: '请输入密码', text: this.password })
        .width('80%')
        .height(50)
        .padding(10)
        .margin({ bottom: 20 })
        .borderRadius(8)
        .border({ width: 1, color: '#E5E5E5' })
        .type(InputType.Password)
        .onChange((value: string) => {
          this.password = value;
          this.clearMessages();
        });

      // 确认密码输入框
      TextInput({ placeholder: '请再次输入密码', text: this.confirmPassword })
        .width('80%')
        .height(50)
        .padding(10)
        .margin({ bottom: 20 })
        .borderRadius(8)
        .border({ width: 1, color: '#E5E5E5' })
        .type(InputType.Password)
        .onChange((value: string) => {
          this.confirmPassword = value;
          this.clearMessages();
        });

      // 昵称输入框
      TextInput({ placeholder: '请输入昵称', text: this.nickName })
        .width('80%')
        .height(50)
        .padding(10)
        .margin({ bottom: 40 })
        .borderRadius(8)
        .border({ width: 1, color: '#E5E5E5' })
        .onChange((value: string) => {
          this.nickName = value;
          this.clearMessages();
        });

      // 注册按钮
      Button('注册', { type: ButtonType.Capsule, stateEffect: true })
        .width('80%')
        .height(50)
        .backgroundColor('#007DFF')
        .fontColor(Color.White)
        .fontSize(18)
        .margin({ bottom: 20 })
        .enabled(!this.isLoading && this.isFormValid())
        .onClick(() => {
          this.handleRegister();
        });

      // 返回登录链接
      Row({ space: 5 }) {
        Text('已有账号？')
          .fontSize(14)
          .fontColor('#666666')
        Text('返回登录')
          .fontSize(14)
          .fontColor('#007DFF')
          .decoration({ type: TextDecorationType.Underline })
          .onClick(() => {
            router.back();
          })
      }
      .margin({ bottom: 30 })

      // 加载中状态
      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(30)
            .height(30)
          Text('注册中...')
            .fontSize(14)
            .fontColor('#666666')
            .margin({ top: 10 })
        }
        .margin({ top: 20 })
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Start)
    .backgroundColor('#F5F5F5')
  }

  // 清除消息
  private clearMessages() {
    this.errorMessage = '';
    this.successMessage = '';
  }

  // 表单验证
  private isFormValid(): boolean {
    return this.username.trim() !== '' &&
      this.password.trim() !== '' &&
      this.confirmPassword.trim() !== '' &&
      this.nickName.trim() !== '' &&
      this.password === this.confirmPassword;
  }

  // 注册处理函数 - 使用明文密码
  private async handleRegister() {
    // 表单验证
    if (!this.username.trim() || !this.password.trim() || !this.nickName.trim()) {
      this.errorMessage = '请填写完整信息';
      return;
    }

    if (this.password !== this.confirmPassword) {
      this.errorMessage = '两次输入的密码不一致';
      return;
    }

    if (this.password.length < 6) {
      this.errorMessage = '密码长度不能少于6位';
      return;
    }

    this.isLoading = true;
    this.clearMessages();

    try {
      // 构建注册请求数据 - 直接发送明文密码
      const registerData: RegisterRequestData = {
        username: this.username.trim(),
        password: this.password.trim(), // 明文密码
        nickName: this.nickName.trim()
      };

      console.log('发送注册数据:', registerData);

      // 调用后端注册接口 - 修改路径
      const response: http.HttpResponse = await this.httpRequest.request(
        'http://' + `${this.serverIP}` +'/api/auth/register',
        {
          method: http.RequestMethod.POST,
          header: {
            'Content-Type': 'application/json'
          },
          extraData: JSON.stringify(registerData)
        }
      );

      console.log('注册响应状态:', response.responseCode);
      console.log('注册响应数据:', response.result.toString());

      if (response.responseCode === 200) {
        const result: RegisterResponse = JSON.parse(response.result.toString()) as RegisterResponse;

        console.log('注册成功状态:', result.success);
        if (result.success === true) {  // 改为判断 success
          this.successMessage = '注册成功！';

          // 注册成功后自动登录并保存用户信息
          AppStorage.setOrCreate('userToken', result.data.token);
          AppStorage.setOrCreate('userId', result.data.userId);

          console.log('用户token已保存:', result.data.token);
          console.log('用户ID已保存:', result.data.userId);

          // 2秒后跳转到主页
          setTimeout(() => {
            router.replaceUrl({
              url: 'pages/Index'
            });
          }, 2000);
        } else {
          this.errorMessage = result.message || '注册失败';
        }
      } else {
        this.errorMessage = `网络错误: ${response.responseCode}`;
      }
    } catch (error) {
      console.error('注册请求失败:', error);
      if (error instanceof Error) {
        this.errorMessage = `网络连接失败: ${error.message}`;
      } else {
        this.errorMessage = '网络连接失败，请检查服务器地址';
      }
    } finally {
      this.isLoading = false;
    }
  }
}