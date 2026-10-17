import { INestApplication, ValidationPipe } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import helmet from 'helmet';
import { AppExceptionFilter } from './common/app-exception.filter.js';

/**
 * main.ts와 e2e 테스트가 똑같이 쓰는 앱 설정.
 * 여기 없는 설정은 테스트가 확인하지 못하므로, 전역 설정은 모두 이 함수에 둔다.
 */
export function configureApp(app: INestApplication): void {
  const config = app.get(ConfigService);

  app.use(helmet());
  app.enableCors({
    origin: config.getOrThrow<string[]>('CORS_ORIGINS'),
    credentials: true,
  });
  app.setGlobalPrefix('api');
  app.useGlobalPipes(
    new ValidationPipe({
      transform: true,
      whitelist: true,
      forbidNonWhitelisted: true,
    }),
  );
  app.useGlobalFilters(new AppExceptionFilter());

  // Swagger(/api/docs)는 모든 API 주소와 모양을 보여 준다. 운영에서는 끈다.
  if (config.getOrThrow<string>('NODE_ENV') !== 'production') {
    const document = SwaggerModule.createDocument(
      app,
      new DocumentBuilder()
        .setTitle('Esel API')
        .setDescription('Esel 직접 구축 서버 API')
        .setVersion('0.1.0')
        .addBearerAuth()
        .build(),
    );
    SwaggerModule.setup('api/docs', app, document);
  }
}
