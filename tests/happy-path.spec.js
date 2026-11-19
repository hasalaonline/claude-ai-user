import { test, expect } from '@playwright/test';

test('a new user can sign up and create a project', async ({ page }) => {
  await page.goto('/');
  await page.getByLabel('Name').fill('Test User');
  await page.getByLabel('Email').fill(`test-${Date.now()}@example.com`);
  await page.getByLabel('Password').fill('password123');
  await page.getByRole('button', { name: 'Create account' }).click();

  await expect(page.getByRole('heading', { name: 'Your projects' })).toBeVisible();
  await page.getByRole('button', { name: '+ New project' }).click();
  await page.getByLabel('Project name').fill('Website redesign');
  await page.getByRole('button', { name: 'Save project' }).click();

  await expect(page.getByText('Website redesign')).toBeVisible();
});
