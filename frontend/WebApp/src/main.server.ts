import { BootstrapContext, bootstrapApplication } from '@angular/platform-browser';
import { AppComponent as App } from './app/app';
import { config } from './app/app.config.server';

const bootstrap = (context: BootstrapContext) =>
    bootstrapApplication(App, config, context);

export default bootstrap;
