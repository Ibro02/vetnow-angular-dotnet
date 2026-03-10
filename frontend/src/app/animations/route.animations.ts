import {
  trigger,
  transition,
  style,
  animate,
  query,
  group,
} from '@angular/animations';

export const routeFadeAnimation = trigger('routeAnimation', [
  transition('* <=> *', [
    query(':enter, :leave', [
      style({
        position: 'absolute',
        top: 0,
        left: 0,
        width: '100%',
      }),
    ], { optional: true }),

    group([
      query(':leave', [
        style({ opacity: 1, transform: 'translateY(0)' }),
        animate('250ms cubic-bezier(0.4, 0, 0.2, 1)',
          style({ opacity: 0, transform: 'translateY(-12px)' })
        ),
      ], { optional: true }),

      query(':enter', [
        style({ opacity: 0, transform: 'translateY(16px)' }),
        animate('350ms 100ms cubic-bezier(0.0, 0.0, 0.2, 1)',
          style({ opacity: 1, transform: 'translateY(0)' })
        ),
      ], { optional: true }),
    ]),
  ]),
]);
